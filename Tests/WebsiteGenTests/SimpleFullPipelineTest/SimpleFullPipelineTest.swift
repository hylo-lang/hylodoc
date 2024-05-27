import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import StandardLibraryCore
import Stencil
import WebsiteGen
import XCTest

@testable import WebsiteGen

final class SimpleFullPipelineTest: XCTestCase {
  func test() {
    let fileManager = FileManager.default

    
    let sourceURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("ExampleModule")
      
    let outputURL = URL(fileURLWithPath: "./dist")

    if fileManager.fileExists(atPath: outputURL.path) {
      try! fileManager.removeItem(at: outputURL)
    }


    var diagnostics = DiagnosticSet()
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)
    let rootModuleId = try! ast.makeModule(
      "ExampleModule", sourceCode: sourceFiles(in: [sourceURL]),
      builtinModuleAccess: true, diagnostics: &diagnostics)

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics, tracingInferenceIf: { (_, _) in false })

    XCTAssert(diagnostics.isEmpty)

    let result = extractDocumentation(
      typedProgram: typedProgram,
      for: [
        .init(name: "ExampleModule", rootFolderPath: sourceURL, astId: rootModuleId)
      ])

    switch result {
    case .success(let documentationDatabase):
      generateDocumentation(
        documentation: documentationDatabase,
        typedProgram: typedProgram,
        target: outputURL
      )
      print("Documentation successfully generated at \(outputURL).")
    case .failure(let error):
      print("Failed to extract documentation: \(error)")

      XCTFail()
    }
  }
}
