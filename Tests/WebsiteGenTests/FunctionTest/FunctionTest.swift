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

final class FunctionTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloFunction")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloFunction",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [FunctionDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = FunctionDecl.ID(n) {
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
        let functionId = visitor.listOfProductTypes[0]
        let fDoc = FunctionDocumentation(
        documentation: CommonFunctionDocumentation(
            common: GeneralDescriptionFields(
                summary: .document([.paragraph(Text(
                        "Carving up a summary for dinner, minding my own business."
                    ))]),
                description: .document([.paragraph(Text(
                        "In storms my husband Wilbur in a jealous description. He was crazy!"
                    ))]),
                seeAlso: [
                    .document([.paragraph(Text(
                        "And then he ran into my first see also."
                    ))]),
                    .document([.paragraph(Text(
                        "He ran into my second see also 10 times..."
                    ))])
                ]
            ),
                preconditions: [],
                postconditions: [],
                returns: nil,
                throwsInfo: nil,
                parameters: [:],
                genericParameters: [:]
            )
        )
        
        var targetPath = TargetPath(ctx: ctx)
        targetPath.push(decl: AnyDeclID(functionId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(functionId)), filePath: targetPath.url, parent: nil)
        
        let res = try! renderFunctionPage(ctx: ctx, of: functionId, with: fDoc)
        
        XCTAssertTrue(res.contains("<h1>examleFunction</h1>"), res)
        XCTAssertTrue(matchPattern(match: [
            "<code>",
            "public fun examleFunction() {",
            "return",
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
            "Overview",
            "</h2>",
            "<p>",
            "In storms my husband Wilbur in a jealous description. He was crazy!",
            "</p>",
        ], in: res), res)
    }
}
