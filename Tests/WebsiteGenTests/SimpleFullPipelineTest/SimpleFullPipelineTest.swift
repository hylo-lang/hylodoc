import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import HyloStandardLibrary
import Stencil
import TestUtils
import WebsiteGen
import XCTest

@testable import WebsiteGen

func runFullPipelineWithoutErrors(
  at sourceUrl: URL, file: StaticString = #filePath, line: UInt = #line
) throws {
  let outputURL = URL(fileURLWithPath: "./test-output/" + UUID.init().uuidString)

  let fileManager = FileManager.default

  if fileManager.fileExists(atPath: outputURL.path) {
    try fileManager.removeItem(at: outputURL)
  }

  var ast = try checkNoDiagnostic { d in
    try AST.loadStandardLibraryCore(diagnostics: &d)
  }

  let rootModuleId = try checkNoDiagnostic { d in
    try ast.makeModule(
      "ExampleModule", sourceCode: sourceFiles(in: [sourceUrl]),
      builtinModuleAccess: true, diagnostics: &d)
  }

  let typedProgram = try checkNoDiagnostic { d in
    try TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &d, tracingInferenceIf: { (_, _) in false }
    )
  }

  let result = extractDocumentation(
    typedProgram: typedProgram,
    for: [
      .init(
        name: "ExampleModule", rootFolderPath: sourceUrl, astId: rootModuleId,
        openSourceUrlBase: URL(
          string: "https://github.com/hylo-lang/hylo/blob/main/StandardLibrary/Sources/")!)
    ])

  switch result {
  case .success(let documentationDatabase):
    guard
      generateDocumentation(
        documentation: documentationDatabase,
        typedProgram: typedProgram,
        exportPath: outputURL
      )
    else {
      return XCTFail("failed to generate documentation", file: file, line: line)
    }
  case .failure(let error):
    XCTFail("Failed to extract documentation: \(error)", file: file, line: line)
  }
}

final class SimpleFullPipelineTest: XCTestCase {
  func test() throws {
    try runFullPipelineWithoutErrors(
      at: URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(
        "ExampleModule", isDirectory: true))
  }
}
