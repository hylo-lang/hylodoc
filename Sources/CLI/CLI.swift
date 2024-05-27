import ArgumentParser
import Foundation
import DocExtractor
import WebsiteGen
import DocumentationDB
import FrontEnd
import StandardLibraryCore

public struct CLI: ParsableCommand {
  public static let configuration = CommandConfiguration(
    abstract: "A Swift command-line tool to compile documentation from Hylo source files and generate HTML. ",
    usage: "hdc <source-path> --output <output-path>"
  )
  
  @Argument(help: "The path to the source bundle. ")
  var sourceBundlePath: String

  @Option(name: .shortAndLong, help: "The output path for the HTML files. ")
  var outputPath: String = "./dist"

  public init() {}

  public func run() throws {
    let fileManager = FileManager.default

    let sourceURL = URL(fileURLWithPath: sourceBundlePath)
    let outputURL = URL(fileURLWithPath: outputPath)

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
      throw ValidationError("Source path '\(sourceURL.path)' does not exist or is not a directory. ")
    }


    if fileManager.fileExists(atPath: outputURL.path) {
      try fileManager.removeItem(at: outputURL)
    }

    var diagnostics = DiagnosticSet()
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)
    let rootModuleId = try! ast.makeModule("root", sourceCode: sourceFiles(in: [sourceURL]), 
      builtinModuleAccess: true, diagnostics: &diagnostics)

    let typedProgram = try TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics, tracingInferenceIf: { (_, _) in false })
        
    guard diagnostics.isEmpty else {
      print("TypedProgram diagnostics errors found: \(diagnostics.description)")
      throw NSError(domain: "CLIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "TypedProgram diagnostics errors found."])
    }

    let result = extractDocumentation(
      typedProgram: typedProgram,
      for: [
        .init(name: "rootModule", rootFolderPath: sourceURL, astId: rootModuleId)
      ])
        
    switch result {
      case .success(let documentationDatabase):
        generateDocumentation(
          documentation: documentationDatabase,
          typedProgram: typedProgram,
          target: outputURL
        )
        print("Documentation successfully generated at \(outputPath).")
      case .failure(let error):
          print("Failed to extract documentation: \(error)")
          throw NSError(domain: "CLIError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract documentation: \(error)"])
        } 
  }
}