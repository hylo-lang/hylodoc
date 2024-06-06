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

final class SubscriptTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloSubscript")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloSubscript",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [SubscriptDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = SubscriptDecl.ID(n) {
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
        
        var ctx = GenerationContext(
            documentation: .init(),
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
        )

        //Verify we get any id at all
        XCTAssertTrue(visitor.listOfProductTypes.count > 0)

        // get product type by its id
        let subscriptId = visitor.listOfProductTypes[0]
        let subscriptDoc = SubscriptDeclDocumentation(
            documentation: SubscriptCommonDocumentation(
                generalDescription: GeneralDescriptionFields(
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
                yields: nil,
                throwsInfo: nil,
                parameters: [:],
                genericParameters: [:]
            )
        )
        
        var targetPath = TargetPath(ctx: ctx)
        targetPath.push(decl: AnyDeclID(subscriptId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(subscriptId)), filePath: targetPath.url, parent: nil)
        
        let res = try! renderSubscriptPage(ctx: ctx, of: subscriptId, with: subscriptDoc)
        
        // XCTAssertTrue(res.contains("<h1>min</h1>"), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<code>",
        //     "subscript min<T: Comparable>(_ a: T, _ b: T): T {",
        //     "let { yield if a > b { b } else { a } }",
        //     "}",
        //     "</code>"
        // ], in: res), res)
        XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
            "<p>",
            "Carving up a summary for dinner, minding my own business.",
            "</p>",
        ], in: res), res)
        XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Details",
            "</h1>",
            "<p>",
            "In storms my husband Wilbur in a jealous description. He was crazy!",
            "</p>",
        ], in: res), res)

        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "See Also",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Preconditions",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Postconditions",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Yields",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Throws Info",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Parameters",
            "</h1>",
        ], in: res), res)
        XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
            "<h1>",
            "Generic Parameters",
            "</h1>",
        ], in: res), res)
    }
}
