import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
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

    let references = backReferencesOfTarget(
      targetId: .decl(AnyDeclID(bindingId)),
      typedProgram: typedProgram,
      documentationDatabase: .init()
    )
    XCTAssertEqual(references.count, 2) // 2 vardecls

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

    let references = backReferencesOfTarget(
      targetId: .decl(AnyDeclID(bindingId)),
      typedProgram: typedProgram,
      documentationDatabase: .init())

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

  func testReferForBackReferenceOfBindings() {
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
    let references = backReferencesOfTarget(
      targetId: .decl(AnyDeclID(bindingId)),
      typedProgram: typedProgram,
      documentationDatabase: .init()
    )

    var targetResolver: TargetResolver = .init()

    targetResolver.resolve(
      targetId: .decl(AnyDeclID(bindingId)),
      ResolvedTarget(
        id: .decl(AnyDeclID(bindingId)),
        parent: nil,
        simpleName: "placeholder",
        navigationName: "placeholder",
        children: [],
        url: URL(fileURLWithPath: "/index.html")
      )
    )

    references.forEach {
      targetResolver.resolveBackReference(
        from: $0,
        backTo: .decl(AnyDeclID(bindingId))
      )

      XCTAssertEqual(targetResolver.url(to: $0)?.path, "/index.html")
    }
  }

  func testBackReferenceOfIndexHylodoc() throws {
    let outputURL = URL(fileURLWithPath: "./test-output/" + UUID.init().uuidString)

    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: outputURL.path) {
      try fileManager.removeItem(at: outputURL)
    }

    var ast = try checkNoDiagnostic { d in
      try AST.loadStandardLibraryCore(diagnostics: &d)
    }
    let sourceUrl = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("TestHyloModule")
    let rootModuleId = try checkNoDiagnostic { d in
      try ast.makeModule(
        "TestHyloModule", sourceCode: sourceFiles(in: [sourceUrl]),
        builtinModuleAccess: true, diagnostics: &d)
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast),
        reportingDiagnosticsTo: &d
      )
    }

    let result = extractDocumentation(
      typedProgram: typedProgram,
      for: [
        .init(name: "TestHyloModule", rootFolderPath: sourceUrl, astId: rootModuleId)
      ])

    let documentationDatabase: DocumentationDatabase
    switch result {
    case .success(let db):
      documentationDatabase = db
    case .failure(let error):
      print("Failed to extract documentation: \(error)")
      return XCTFail()
    }

    let rootFolderId = documentationDatabase.modules[rootModuleId]!.rootFolder
    let indexArticleId: ArticleAsset.ID = documentationDatabase.assets.articles.firstIndex {
      $0.isIndexPage
    }!

    XCTAssertEqual(
      backReferencesOfTarget(
        targetId: .asset(.folder(rootFolderId)), typedProgram: typedProgram,
        documentationDatabase: documentationDatabase
      ),
      [.asset(.article(indexArticleId))]
    )
  }

  func testResolveUrlToOtherTarget() {
    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .empty  // dummy target

    targetResolver.resolveOther(
      targetId: targetId,
      ResolvedDirectlyCopiedAssetTarget(
        sourceUrl: URL(fileURLWithPath: "./some/path/localFile.pdf"),
        url: URL(fileURLWithPath: "/some/path/localFile.pdf")
      )
    )

    XCTAssertEqual(targetResolver.url(to: targetId)?.path, "/some/path/localFile.pdf")
  }
}
