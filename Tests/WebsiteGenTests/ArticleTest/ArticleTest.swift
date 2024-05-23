import XCTest
@testable import WebsiteGen
import Stencil
import DocumentationDB
import StandardLibraryCore
import MarkdownKit

@testable import FrontEnd

final class ArticleTest: XCTestCase {
    func testArticlePageGenerationWithTitle() {

        var diagnostics = DiagnosticSet()

        /// An instance that includes just the standard library.
        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("TestHyloArticle")

        // The module whose Hylo files were given on the command-line
        let _ = try! ast.makeModule(
            "TestHyloArticle",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        let typedProgram = try! TypedProgram(
          annotating: ScopedProgram(ast), inParallel: false,
          reportingDiagnosticsTo: &diagnostics,
          tracingInferenceIf: { (_,_: TypedProgram) in false })
        
        var db: DocumentationDatabase = .init()

        let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));

        let ctx = GenerationContext(
            documentation: db,
            stencil: stencil,
            typedProgram: typedProgram
        )

        let article1Id = db.assets.articles.insert(.init(
            location: URL(string: "root/Folder1/article1.hylodoc")!,
            title: "I betcha you would have done the same",
            content: Block.paragraph(Text("Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!"))
        ))

        var res: String = ""
        do {
            res = try renderArticlePage(ctx: ctx, of: db.assets.articles[article1Id]!)
        } catch {
            XCTFail("Should not throw")
        }

        XCTAssertTrue(res.contains("<h1>I betcha you would have done the same</h1>"), res)
        XCTAssertTrue(res.contains("<p>Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!</p>"), res)
    }

    func testArticlePageGenerationNoTitle() {

        var diagnostics = DiagnosticSet()

        /// An instance that includes just the standard library.
        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("TestHyloArticle")

        // The module whose Hylo files were given on the command-line
        let _ = try! ast.makeModule(
            "TestHyloArticle",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        let typedProgram = try! TypedProgram(
          annotating: ScopedProgram(ast), inParallel: false,
          reportingDiagnosticsTo: &diagnostics,
          tracingInferenceIf: { (_,_: TypedProgram) in false })
        
        var db: DocumentationDatabase = .init()

        let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));

        let ctx = GenerationContext(
            documentation: db,
            stencil: stencil,
            typedProgram: typedProgram
        )

        let article1Id = db.assets.articles.insert(.init(
            location: URL(string: "root/Folder1/article1.hylodoc")!,
            title: nil,
            content: Block.paragraph(Text("Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!"))
        ))

        var res: String = ""
        do {
            res = try renderArticlePage(ctx: ctx, of: db.assets.articles[article1Id]!)
        } catch {
            XCTFail("Should not throw")
        }

        XCTAssertTrue(res.contains("<h1>article1</h1>"), res)
        XCTAssertTrue(res.contains("<p>Carving up a chicken for dinner. Minding my own business. In storms my husband Wilbur in a jealous rage. He was crazy!</p>"), res)
    }
}