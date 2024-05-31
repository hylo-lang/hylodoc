import Foundation
import DocumentationDB
import FrontEnd
import MarkdownKit
import Stencil
import StandardLibraryCore
import XCTest
import PathWrangler

@testable import WebsiteGen

final class TypeAliasTest : XCTestCase {
    func test() {
        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)
        
        // We don't really read anything from here right now, we will the documentation database manually
        let libraryPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestHyloModule")

        // The module whose Hylo files were given on the command-line
        let moduleId = try! ast.makeModule(
            "TestHyloModule",
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
          var listOfProductTypes: [TypeAliasDecl.ID] = []

          mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = TypeAliasDecl.ID(n) {
              listOfProductTypes.append(d)
            }
            return true
          }
        }
        var visitor = ASTWalkingVisitor()
        ast.walk(moduleId, notifying: &visitor)

        let typedProgram = try! TypedProgram(
                  annotating: ScopedProgram(ast),
                  inParallel: false,
                  reportingDiagnosticsTo: &diagnostics,
                  tracingInferenceIf: { (_,_) in false }
                )
        
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
        let typeAliasId = visitor.listOfProductTypes[0]
        let doc: TypeAliasDocumentation = .init(
                        common: .init(
                            summary: .document([.paragraph(Text("Some summary"))]),
                            description: .document([.paragraph(Text("Some description"))]),
                            seeAlso: []
                        )
                    )

                    var targetPath = TargetPath(ctx: ctx)
                    targetPath.push(decl: AnyDeclID(typeAliasId))
                    ctx.urlResolver.resolve(target: .symbol(AnyDeclID(typeAliasId)), filePath: targetPath.url, parent: nil)

                    let content = try! renderTypeAliasPage(ctx: ctx, of: typeAliasId, with: doc)
                    print(content)

                    // Assert
                    XCTAssertTrue(content.contains("Vector2"))
                    XCTAssertTrue(content.contains("Some summary"))
                    XCTAssertTrue(content.contains("Some description"))
    }
}
