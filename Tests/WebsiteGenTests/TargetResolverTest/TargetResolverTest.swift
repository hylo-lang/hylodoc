import Foundation
import FrontEnd
import PathWrangler
import HyloStandardLibrary
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class TargetResolverTest: XCTestCase {
  func testBackReferenceOfBindingOfSingleVar() {
    var diagnostics = DiagnosticSet()

    var ast = try! AST.loadStandardLibraryCore(diagnostics: &diagnostics)

    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files we are using for the test
    let moduleId = try! ast.makeModule(
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

    let bindingId = ast.resolveBinding(byOccurrenceNumber: 0, in: moduleId)!

    guard
      let references = backReferencesOfTarget(typedProgram, targetId: .decl(AnyDeclID(bindingId)))
    else {
      XCTFail("failed to resolve back references of binding decl")
      return
    }

    if case .decl(let declId) = references[0] {
      XCTAssertEqual(declId.kind, NodeKind(VarDecl.self))
    } else {
      XCTFail("expected 1 reference which should be a decl")
    }
  }

  func testBackReferenceOfBindingOfTuple() {
    var diagnostics = DiagnosticSet()

    var ast = try! AST.loadStandardLibraryCore(diagnostics: &diagnostics)

    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files we are using for the test
    let moduleId = try! ast.makeModule(
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

    let bindingId = ast.resolveBinding(byOccurrenceNumber: 1, in: moduleId)!

    guard
      let references = backReferencesOfTarget(typedProgram, targetId: .decl(AnyDeclID(bindingId)))
    else {
      XCTFail("failed to resolve back references of binding decl")
      return
    }

    XCTAssertEqual(references.count, 2)  // check if the tuple gives back 2 references
    references.forEach {
      if case .decl(let declId) = $0 {
        XCTAssertEqual(declId.kind, NodeKind(VarDecl.self))
      } else {
        XCTFail("expected reference \($0) to be a decl")
      }
    }

    if case .decl(let declId) = references[0] {
      XCTAssertEqual(declId.kind, NodeKind(VarDecl.self))
    } else {
      XCTFail("expected 1 reference which should be a decl")
    }
  }

  func testReferForBackReference() {
    var diagnostics = DiagnosticSet()

    var ast = try! AST.loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let moduleId = try! ast.makeModule(
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

    let bindingId = ast.resolveBinding(byOccurrenceNumber: 1, in: moduleId)!
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
