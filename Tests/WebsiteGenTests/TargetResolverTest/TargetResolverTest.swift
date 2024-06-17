import Foundation
import FrontEnd
import PathWrangler
import StandardLibraryCore
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class TargetResolverTest: XCTestCase {
  func testBackReferenceOfBinding() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    let bindingId = ast.resolveBinding(by: "x")!

    guard
      let references = backReferencesOfTarget(typedProgram, targetId: .decl(AnyDeclID(bindingId)))
    else {
      XCTFail("failed to resolve back references of binding decl")
      return
    }

    XCTAssertEqual(references.count, 1)
  }

  func testReferForBackReference() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    let bindingId = ast.resolveBinding(by: "x")!
    let references = backReferencesOfTarget(typedProgram, targetId: .decl(AnyDeclID(bindingId)))!

    var targetResolver: TargetResolver = .init()
    targetResolver.resolve(
      targetId: .decl(AnyDeclID(bindingId)),
      ResolvedTarget(
        id: .decl(AnyDeclID(bindingId)),
        parent: nil,
        simpleName: "placeholder",
        navigationName: "placeholder",
        children: [],
        relativePath: RelativePath(pathString: "index.html")
      )
    )

    references.forEach {
      targetResolver.resolveBackReference(
        from: $0,
        backTo: .decl(AnyDeclID(bindingId))
      )

      XCTAssertEqual(
        targetResolver.refer(from: .empty, to: $0), RelativePath(pathString: "index.html"))
    }
  }
}
