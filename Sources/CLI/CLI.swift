import ArgumentParser
import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import HyloStandardLibrary
import WebsiteGen

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

  public init() {}

  public func run() throws {
    let clock = ContinuousClock()
    let duration = try clock.measure({
      let fileManager = FileManager.default
      let outputURL = URL(fileURLWithPath: outputPath)

      if fileManager.fileExists(atPath: outputURL.path) {
        try fileManager.removeItem(at: outputURL)
      }

      var diagnostics = DiagnosticSet()
      var ast = try AST.loadStandardLibraryCore(diagnostics: &diagnostics)
      var modules: [InputModuleInfo] = []

      for sourceBundlePath in sourceBundlePaths {
        let sourceURL = URL(fileURLWithPath: sourceBundlePath)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory),
          isDirectory.boolValue
        else {
          throw ValidationError(
            "Source path '\(sourceURL.path)' does not exist or is not a directory. ")
        }

        let rootModuleId = try! ast.makeModule(
          "\(sourceURL.lastPathComponent)", sourceCode: sourceFiles(in: [sourceURL]),
          builtinModuleAccess: true, diagnostics: &diagnostics)

        modules.append(
          .init(
            name: "\(sourceURL.lastPathComponent)",
            rootFolderPath: sourceURL, astId: rootModuleId))
      }

      guard !modules.isEmpty else {
        print("Failed to generate modules or empty modules.")
        throw NSError(
          domain: "CLIError", code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Failed to generate modules or empty modules."])
      }

      let typedProgram = try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &diagnostics, tracingInferenceIf: { (_, _) in false })

      guard diagnostics.isEmpty else {
        print("TypedProgram diagnostics errors found: \(diagnostics)")
        throw NSError(
          domain: "CLIError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "TypedProgram diagnostics errors found."])
      }

      let result = extractDocumentation(
        typedProgram: typedProgram,
        for: modules
      )

      switch result {
      case .success(let documentationDatabase):
        guard
          generateDocumentation(
            documentation: documentationDatabase,
            typedProgram: typedProgram,
            exportPath: outputURL
          )
        else {
          throw NSError(
            domain: "CLIError", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to generate website."])
        }
      case .failure(let error):
        throw NSError(
          domain: "CLIError", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Failed to extract documentation: \(error)"])
      }
    })

    print("Documentation successfully generated at \(outputPath) in \(duration).")
  }
}
