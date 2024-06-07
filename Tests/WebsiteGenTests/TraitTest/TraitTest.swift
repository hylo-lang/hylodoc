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

final class TraitTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloTrait")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloTrait",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [TraitDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = TraitDecl.ID(n) {
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
        let traitId = visitor.listOfProductTypes[0]
        let traitDoc = TraitDocumentation(
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
        targetPath.push(decl: AnyDeclID(traitId))
        ctx.urlResolver.resolve(target: .symbol(AnyDeclID(traitId)), filePath: targetPath.url, parent: nil)
        
        let res = try! renderTraitPage(ctx: ctx, of: traitId, with: traitDoc)
        
        let _ = res
        // XCTAssertTrue(res.contains("<h1>Shape</h1>"), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<code>",
        //     "trait Shape {",
        //     "static fun name() -> String",
        //     "fun draw(to: inout Int)",
        //     "}",
        //     "</code>"
        // ], in: res), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<h4>",
        //     "<p>",
        //     "Carving up a summary for dinner, minding my own business.",
        //     "</p>",
        //     "</h4>"
        // ], in: res), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<h2>",
        //     "Details",
        //     "</h2>",
        //     "<p>",
        //     "In storms my husband Wilbur in a jealous description. He was crazy!",
        //     "</p>",
        // ], in: res), res)
        // XCTAssertTrue(matchWithWhitespacesInBetween(pattern: [
        //     "<h2>",
        //     "Invariants",
        //     "</h2>",
        //     "<ul>",
        //     "<li>",
        //     "<p>",
        //     "Invariants are cool",
        //     "</p>",
        //     "</li>",
        //     "</ul>",
        // ], in: res), res)

        // XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
        //     "<h2>",
        //     "See Also",
        //     "</h2>",
        // ], in: res), res)
    }
}
