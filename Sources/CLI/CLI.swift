import ArgumentParser
import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import HyloStandardLibrary
import WebsiteGen

// import Vapor

extension DiagnosticSet {
  fileprivate var niceErrorMessage: String {
    return "Diagnostics: \n" + elements.map { " - " + $0.description + "\n" }.joined(by: "")
  }
}
/// The business logic inside the CLI is encapsulated in this struct so that
/// it can be tested independently from the command line parsing, without the
/// need to create a new process for each test.
public struct CLICore {
  public enum CLIError: Error, CustomStringConvertible {
    case sourceModulePathNotFound(path: URL)
    case sourceModulePathNotDirectory(path: URL)
    case failedToParseAST(diagnostics: DiagnosticSet)
    case failedToTypeCheck(diagnostics: DiagnosticSet)
    case noModulesProvided
    case moreThanOneModuleIsProvidedForStandardLibraryDocumentation
    case failedToExtractDocumentation(error: any Error)
    case failedToGenerateWebsite
    case failedToLoadStandardLibrary(diagnostics: DiagnosticSet)

    public var description: String {
      switch self {
      case .noModulesProvided:
        return "No modules provided."
      case .sourceModulePathNotFound(let path):
        return "Source module path not found: \(path.absoluteString)"
      case .sourceModulePathNotDirectory(let path):
        return "Source module path is not a directory: \(path.absoluteString)"
      case .failedToParseAST(let diagnostics):
        return "Failed to parse AST. \(diagnostics.niceErrorMessage)"
      case .failedToTypeCheck(let diagnostics):
        return "Failed to type check. \(diagnostics.niceErrorMessage)"
      case .failedToExtractDocumentation(let error):
        return "Failed to extract documentation. \(error)"
      case .failedToGenerateWebsite:
        return "Failed to generate website."
      case .failedToLoadStandardLibrary(let diagnostics):
        return "Failed to load standard library. \(diagnostics.niceErrorMessage)"
      case .moreThanOneModuleIsProvidedForStandardLibraryDocumentation:
        return "More than one module is provided for standard library documentation."
      }

    }
  }

  /// If the output path already exists, it removes it and all its contents.
  ///
  /// - Parameters:
  ///   - modulePaths:
  ///   - outputPath:
  ///   - documentingStandardLibrary: if false, we will load the standard library into the AST,
  ///       otherwise we assume that the passed-in modules are the standard library.
  public func extractDocumentationForModules(
    modulePaths: [URL], outputURL: URL, documentingStandardLibrary: Bool
  ) throws {
    let fileManager = FileManager.default

    if modulePaths.isEmpty {
      throw CLIError.noModulesProvided
    }

    // Remove output directory if exists
    if fileManager.fileExists(atPath: outputURL.path) {
      try fileManager.removeItem(at: outputURL)
    }

    var diagnostics = DiagnosticSet()

    // Load modules into AST depending on the mode
    let (modules, ast) =
      if documentingStandardLibrary {
        try loadStandardLibraryIntoAST(
          modulePaths: modulePaths, diagnostics: &diagnostics, fileManager: fileManager
        )
      } else {
        try loadNormalModulesIntoASTAlongWithStdLib(
          modulePaths: modulePaths, diagnostics: &diagnostics, fileManager: fileManager
        )
      }

    // Type-check program
    let typedProgram: TypedProgram
    do {
      typedProgram = try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &diagnostics, tracingInferenceIf: { (_, _) in false }
      )
    } catch let d as DiagnosticSet {
      throw CLIError.failedToTypeCheck(diagnostics: d)
    }

    // Extract documentation
    let result = extractDocumentation(
      typedProgram: typedProgram,
      for: modules
    )

    let documentationDatabase: DocumentationDatabase

    switch result {
    case .success(let db):
      documentationDatabase = db
    case .failure(let error):
      throw CLIError.failedToExtractDocumentation(error: error)
    }

    // Generate documentation
    guard
      generateDocumentation(
        documentation: documentationDatabase,
        typedProgram: typedProgram,
        exportPath: outputURL
      )
    else { throw CLIError.failedToGenerateWebsite }
  }

  // Calling it with more than one module path is an error.
  private func loadStandardLibraryIntoAST(
    modulePaths: [URL], diagnostics: inout DiagnosticSet, fileManager: FileManager
  ) throws -> ([InputModuleInfo], AST) {
    guard modulePaths.count == 1 else {
      throw CLIError.moreThanOneModuleIsProvidedForStandardLibraryDocumentation
    }

    // Create an empty AST
    var ast = AST(ConditionalCompilationFactors(freestanding: true))

    // Load the standard library module
    let coreLibraryId: ModuleDecl.ID

    do {
      coreLibraryId = try ast.makeModule(
        "Hylo",
        sourceCode: sourceFiles(in: modulePaths),
        builtinModuleAccess: true,
        diagnostics: &diagnostics
      )
    } catch let d as DiagnosticSet {
      throw CLIError.failedToParseAST(diagnostics: d)
    }

    // Loads the core trait data structures from the currently imported module.
    ast.coreLibrary = coreLibraryId
    ast.coreTraits = .init(ast)

    return (
      [
        InputModuleInfo(
          name: "Hylo",
          rootFolderPath: modulePaths[0],
          astId: coreLibraryId
        )
      ],
      ast
    )
  }

  private func loadNormalModulesIntoASTAlongWithStdLib(
    modulePaths: [URL], diagnostics: inout DiagnosticSet, fileManager: FileManager
  ) throws -> ([InputModuleInfo], AST) {
    var ast = try AST.loadStandardLibrary(diagnostics: &diagnostics)

    // Load modules into AST
    let modules = try modulePaths.map { sourceURL in
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
        throw CLIError.sourceModulePathNotFound(path: sourceURL)
      }
      guard isDirectory.boolValue else {
        throw CLIError.sourceModulePathNotDirectory(path: sourceURL)
      }

      let rootModuleId: ModuleDecl.ID
      do {
        rootModuleId = try ast.makeModule(
          "\(sourceURL.lastPathComponent)", sourceCode: sourceFiles(in: [sourceURL]),
          builtinModuleAccess: true, diagnostics: &diagnostics
        )
      } catch let d as DiagnosticSet {
        throw CLIError.failedToParseAST(diagnostics: d)
      }

      return InputModuleInfo(
        name: "\(sourceURL.lastPathComponent)",
        rootFolderPath: sourceURL, astId: rootModuleId
      )
    }

    return (modules, ast)
  }
}

public struct CLI: ParsableCommand {
  public static let configuration = CommandConfiguration(
    abstract:
      "A Swift command-line tool to compile documentation from Hylo source files and generate HTML. ",
    usage: "hdc <source-path> --output <output-path>"
  )

  @Argument(help: "The paths to the source bundle. ")
  var sourceBundlePaths: [String]

  @Option(name: .shortAndLong, help: "The output path for the HTML files. ")
  var outputPath: String = "./dist"

  @Flag(name: .customShort("s"), help: "Document the standard library. ")
  var documentingStandardLibrary: Bool = false

  @Flag(help: "Start a web server to preview the generated documentation. ")
  var preview: Bool = false

  @Option(name: .customShort("p"), help: "The port number for the web server. ")
  var port: Int = 8080

  public init() {}

  public func run() throws {
    let clock = ContinuousClock()
    let duration = try clock.measure({

      let cli = CLICore()

      try cli.extractDocumentationForModules(
        modulePaths: sourceBundlePaths.map { URL(fileURLWithPath: $0) },
        outputURL: URL(fileURLWithPath: outputPath),
        documentingStandardLibrary: documentingStandardLibrary
      )
    })

    print("Documentation successfully generated at \(outputPath) in \(duration).")

    guard preview else { return }
    print("Starting preview server... 🚀")
    try startWebserverSync(port: port, publicDirectory: URL(fileURLWithPath: outputPath))
  }
}
