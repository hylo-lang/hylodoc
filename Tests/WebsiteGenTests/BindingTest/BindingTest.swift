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

final class BindingTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloBinding")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloBinding",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [BindingDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = BindingDecl.ID(n) {
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
        let bindingId = visitor.listOfProductTypes[0]
        let bindingDoc = BindingDocumentation(
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
        targetPath.push(decl: AnyDeclID(bindingId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(bindingId)), filePath: targetPath.url, parent: nil)
        
        let res = try! renderBindingPage(ctx: ctx, of: bindingId, with: bindingDoc)
        
        XCTAssertTrue(res.contains("<h1>binding</h1>"), res)
        XCTAssertTrue(matchPattern(match: [
            "<code>",
            "let x = 5",
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
        XCTAssertTrue(matchPattern(match: [
            "<h2>",
            "Invariants",
            "</h2>",
            "<ul>",
            "<li>",
            "<p>",
            "Invariants are cool",
            "</p>",
            "</li>",
            "</ul>",
        ], in: res), res)

        XCTAssertFalse(matchPattern(match: [
            "<h2>",
            "See Also",
            "</h2>",
        ], in: res), res)
    }
}