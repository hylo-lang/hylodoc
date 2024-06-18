import DocumentationDB
import HyloStandardLibrary
import MarkdownKit
import Stencil
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class ArticleTest: XCTestCase {
  func testArticlePageGenerationWithTitle() throws {
    var ast = try checkNoDiagnostic { d in try AST.loadStandardLibraryCore(diagnostics: &d) }

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try checkNoDiagnostic { d in
      try ast.makeModule(
        "TestHyloModule",
        sourceCode: sourceFiles(in: [libraryPath]),
        builtinModuleAccess: true,
        diagnostics: &d
      )
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in false }
      )
    }

    var db: DocumentationDatabase = .init()

    let articleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/article1.hylodoc")!,
        title: "I betcha you would have done the same",
        content: .document([
          .paragraph(
            Text(
              "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!"
            ))
        ]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.article(articleId))
    let partialResolved = partialResolveAsset(db, typedProgram, assetId: .article(articleId))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children,
        url: URL(fileURLWithPath: "/")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(URL(fileURLWithPath: "/")),
      breadcrumb: [],
      tree: ""
    )

    let stencilContext = try prepareArticlePage(context, of: articleId)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("I betcha you would have done the same", in: res)
    assertContent(
      "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!",
      in: res,
      file: #file, line: #line
    )
  }

  func testArticlePageGenerationNoTitle() throws {

    var ast = try checkNoDiagnostic { d in
      try AST.loadStandardLibraryCore(diagnostics: &d)
    }

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try checkNoDiagnostic { d in
      try ast.makeModule(
        "TestHyloModule",
        sourceCode: sourceFiles(in: [libraryPath]),
        builtinModuleAccess: true,
        diagnostics: &d
      )
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in false }
      )
    }

    var db: DocumentationDatabase = .init()

    let article1Id = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/article1.hylodoc")!,
        title: nil,
        content: .document([
          .paragraph(
            Text(
              "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!"
            )
          )
        ]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.article(article1Id))
    let partialResolved = partialResolveAsset(db, typedProgram, assetId: .article(article1Id))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children,
        url: URL(fileURLWithPath: "/")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(URL(fileURLWithPath: "/")),
      breadcrumb: [],
      tree: ""
    )

    let stencilContext = try prepareArticlePage(context, of: article1Id)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("article1", in: res)
    assertContent(
      "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!",
      in: res,
      file: #file, line: #line
    )
  }
}
