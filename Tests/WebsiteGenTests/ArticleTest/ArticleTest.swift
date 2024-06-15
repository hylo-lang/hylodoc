import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest
import TestUtils

@testable import FrontEnd
@testable import WebsiteGen

final class ArticleTest: XCTestCase {
    func testArticlePageGenerationWithTitle() {
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
            tracingInferenceIf: { (_, _) in false })

        var db: DocumentationDatabase = .init()

        let article1Id = db.assets.articles.insert(
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

        var ctx = GenerationContext(
            documentation: db,
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
            tree: []
        )

        ctx.urlResolver.resolve(target: .asset(.article(article1Id)), filePath: RelativePath(pathString: "root/Folder1/article1.hylodoc"), parent: nil)

        let res = try! renderArticlePage(ctx: &ctx, of: article1Id)

        assertPageTitle("I betcha you would have done the same", in: res, file: #file, line: #line)
        assertContent(
            "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!",
            in: res,
            file: #file, line: #line
        )
  }
  
    func testArticlePageGenerationNoTitle() {
        
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
            tracingInferenceIf: { (_, _) in false })

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

        var ctx = GenerationContext(
            documentation: db,
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
            tree: []
        )

        ctx.urlResolver.resolve(target: .asset(.article(article1Id)), filePath: RelativePath(pathString: "root/Folder1/article1.hylodoc"), parent: nil)

        let res = try! renderArticlePage(ctx: &ctx, of: article1Id)

        assertPageTitle("article1", in: res, file: #file, line: #line)
        assertContent(
            "Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!",
            in: res,
            file: #file, line: #line
        )
  }
}
