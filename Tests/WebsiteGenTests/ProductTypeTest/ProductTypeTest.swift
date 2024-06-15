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

final class ProductTypeTest : XCTestCase {
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
        let productTypeId = ast.resolveProductType(by: "Vector2")!
        let productTypeDoc = ProductTypeDocumentation(
            common: GeneralDescriptionFields(
                summary: .document([.paragraph(Text(
                        "Carving up a summary for dinner, minding my own business."
                    ))]),
                description: .document([.paragraph(Text(
                        "In storms my husband Wilbur in a jealous description. He was crazy!"
                    ))]),
                seeAlso: []
            ),
            invariants: [
                Invariant(description: .document([.paragraph(Text("Invariants are cool"))]))
            ]
        )

        var targetPath = TargetPath(ctx: ctx)
        targetPath.push(decl: AnyDeclID(productTypeId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(productTypeId)), filePath: targetPath.url, parent: nil)

        let res = try! renderProductTypePage(ctx: &ctx, of: productTypeId, with: productTypeDoc)

        assertPageTitle("type Vector2", in: res, file: #file, line: #line)
        assertSummary("Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line)
        assertDetails("In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file, line: #line)
        assertListExistAndCount(id: "invariants", count: 1, in: res, file: #file, line: #line)

        // let members = findByID("members", in: res)
        assertSectionsExsistingAndCount(
            [
                "Associated Types": 0,
                "Associated Values": 0,
                "Type Aliases": 1,
                "Bindings": 2,
                "Operators": 0,
                "Functions": 0,
                "Methods": 1,
                "Subscripts": 0,
                "Initializers": 2,
                "Traits": 0,
                "Product Types": 0,
            ],
            // in: members,
            in: res,
            file: #file, line: #line
        )

        assertNotContains(res, what: "seeAlso", file: #file, line: #line)

    }
}