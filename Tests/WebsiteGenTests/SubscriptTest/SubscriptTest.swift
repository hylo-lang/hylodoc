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

        let db: DocumentationDatabase = .init()
        let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))
        
        var ctx = GenerationContext(
            documentation: db,
            stencil: stencil,
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
        
        XCTAssertTrue(res.contains("<h1>min</h1>"), res)
        XCTAssertTrue(matchPattern(match: [
            "<code>",
            "subscript min<T: Comparable>(_ a: T, _ b: T): T {",
            "let { yield if a > b { b } else { a } }",
            "}",
            "</code>"
        ], in: res), res)
        XCTAssertTrue(matchPattern(match: [
            "<h4>",
            "<p>",
            "Carving up a summary for dinner, minding my own business.",
            "</p>",
            "</h4>"
        ], in: res), res)
        XCTAssertTrue(matchPattern(match: [
            "<h2>",
            "Details",
            "</h2>",
            "<p>",
            "In storms my husband Wilbur in a jealous description. He was crazy!",
            "</p>",
        ], in: res), res)

        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "See Also",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Preconditions",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Postconditions",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Yields",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Throws Info",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Parameters",
            "</h2>",
        ], in: res), res)
        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "Generic Parameters",
            "</h2>",
        ], in: res), res)
    }
}
