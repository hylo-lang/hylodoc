import Foundation
import DocumentationDB
import FrontEnd
import MarkdownKit
import Stencil
import StandardLibraryCore
import XCTest
import PathWrangler

@testable import FrontEnd
@testable import WebsiteGen

final class OperatorTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloOperator")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloOperator",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [OperatorDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = OperatorDecl.ID(n) {
              listOfProductTypes.append(d)
            }
            return true
          }
        }
        var visitor = ASTWalkingVisitor()
        ast.walk(moduleId, notifying: &visitor)

        let typedProgram = try! TypedProgram(
            annotating: ScopedProgram(ast), inParallel: false,
            reportingDiagnosticsTo: &diagnostics,
            tracingInferenceIf: { (_, _) in false })

        let db: DocumentationDatabase = .init()
        
        var ctx = GenerationContext(
            documentation: db,
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
        )

        //Verify we get any id at all
        XCTAssertTrue(visitor.listOfProductTypes.count > 0)

        // get product type by its id
        let operatorId = visitor.listOfProductTypes[0]
        let operatorDoc = OperatorDocumentation(documentation: GeneralDescriptionFields(
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
        
        let res = try! renderOperatorPage(ctx: ctx, of: operatorId, with: operatorDoc)
        let _ = res
        // XCTAssertTrue(res.contains("<h1>==</h1>"), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<code>",
        //     "public operator infix== : comparison",
        //     "</code>"
        // ], in: res), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<p>",
        //     "Carving up a summary for dinner, minding my own business.",
        //     "</p>",
        // ], in: res), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<h1>",
        //     "Details",
        //     "</h1>",
        //     "<p>",
        //     "In storms my husband Wilbur in a jealous description. He was crazy!",
        //     "</p>",
        // ], in: res), res)

        // XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
        //     "<h1>",
        //     "See Also",
        //     "</h1>",
        // ], in: res), res)
    }
}
