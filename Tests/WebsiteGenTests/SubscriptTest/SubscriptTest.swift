import Foundation
import DocumentationDB
import FrontEnd
import MarkdownKit
import Stencil
import StandardLibraryCore
import XCTest
import PathWrangler
import TestUtils

@testable import FrontEnd
@testable import WebsiteGen

final class SubscriptTest : XCTestCase {
    func test() {
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

        var ctx = GenerationContext(
            documentation: .init(),
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
            tree: []
        )

        // get product type by its id
        let subscriptId = ast.resolveSubscriptDecl(by: "min")!
        let subscriptDoc = SubscriptDeclDocumentation(
            documentation: CommonFunctionDeclLikeDocumentation(
                common: CommonFunctionLikeDocumentation(
                    common: GeneralDescriptionFields(
                        summary: .document([.paragraph(Text(
                                "Carving up a summary for dinner, minding my own business."
                            ))]),
                        description: .document([.paragraph(Text(
                                "In storms my husband Wilbur in a jealous description. He was crazy!"
                            ))]),
                        seeAlso: []
                    ),
                    preconditions: [],
                    postconditions: [],
                    throwsInfo: []
                ),
                parameters: [:],
                genericParameters: [:]
            ),
            yields: []
        )

        var targetPath = TargetPath(ctx: ctx)
        targetPath.push(decl: AnyDeclID(subscriptId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(subscriptId)), filePath: targetPath.url, parent: nil)

        let res = try! renderSubscriptPage(ctx: &ctx, of: subscriptId, with: subscriptDoc)

        assertPageTitle("subscript min(_:_:)", in: res, file: #file, line: #line)
        assertSummary("Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line)
        assertDetails("In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file, line: #line)

        assertNotContains(res, what: "yields", file: #file, line: #line)
        assertNotContains(res, what: "throwsInfo", file: #file, line: #line)
        assertNotContains(res, what: "parameters", file: #file, line: #line)
        assertNotContains(res, what: "genericParameters", file: #file, line: #line)
        assertNotContains(res, what: "seeAlso", file: #file, line: #line)
    }
}
