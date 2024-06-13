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

final class OperatorTest : XCTestCase {
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
            htmlGenerator: CustomHTMLGenerator(),
            tree: []
        )

        // get product type by its id
        let operatorId = ast.resolveOperator()!.first!
        let operatorDoc = OperatorDocumentation(
            common: GeneralDescriptionFields(
                summary: .document([.paragraph(Text(
                            "Carving up a summary for dinner, minding my own business."
                        ))]),
                description: .document([.paragraph(Text(
                    "In storms my husband Wilbur in a jealous description. He was crazy!"
                ))]),
                seeAlso: []
        ))

        var targetPath = TargetPath(ctx: ctx)
        targetPath.push(decl: AnyDeclID(operatorId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(operatorId)), filePath: targetPath.url, parent: nil)

        let res = try! renderOperatorPage(ctx: &ctx, of: operatorId, with: operatorDoc)

        assertPageTitle("public operator infix", in: res, file: #file, line: #line)
        assertSummary("Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line)
        assertDetails("In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file, line: #line)

        assertNotContains(res, what: "seeAlso", file: #file, line: #line)
    }
}
