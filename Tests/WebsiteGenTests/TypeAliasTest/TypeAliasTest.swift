// import DocumentationDB
// import Foundation
// import FrontEnd
// import MarkdownKit
// import PathWrangler
// import StandardLibraryCore
// import Stencil
// import XCTest

// @testable import WebsiteGen

// final class TypeAliasTest: XCTestCase {
//   func test() {
//     var diagnostics = DiagnosticSet()

//     var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

//     // We don't really read anything from here right now, we will the documentation database manually
//     let libraryPath = URL(fileURLWithPath: #filePath)
//       .deletingLastPathComponent()
//       .appendingPathComponent("TestHyloModule")

//     // The module whose Hylo files were given on the command-line
//     let moduleId = try! ast.makeModule(
//       "TestHyloModule",
//       sourceCode: sourceFiles(in: [libraryPath]),
//       builtinModuleAccess: true,
//       diagnostics: &diagnostics
//     )

//     struct ASTWalkingVisitor: ASTWalkObserver {
//       var listOfProductTypes: [TypeAliasDecl.ID] = []

//       mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
//         // pattern match the type of node:
//         if let d = TypeAliasDecl.ID(n) {
//           listOfProductTypes.append(d)
//         }
//         return true
//       }
//     }
//     var visitor = ASTWalkingVisitor()
//     ast.walk(moduleId, notifying: &visitor)

//     let typedProgram = try! TypedProgram(
//       annotating: ScopedProgram(ast),
//       inParallel: false,
//       reportingDiagnosticsTo: &diagnostics,
//       tracingInferenceIf: { (_, _) in false }
//     )

//     let db: DocumentationDatabase = .init()

//     var ctx = GenerationContext(
//       documentation: db,
//       stencil: createDefaultStencilEnvironment(),
//       typedProgram: typedProgram,
//       urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
//     )

//     //Verify we get any id at all
//     XCTAssertTrue(visitor.listOfProductTypes.count > 0)

//     // get product type by its id
//     let typeAliasId = visitor.listOfProductTypes[0]
//     let doc: TypeAliasDocumentation = .init(
//       common: .init(
//         summary: .document([.paragraph(Text("Some summary"))]),
//         description: .document([.paragraph(Text("Some description"))]),
//         seeAlso: []
//       )
//     )

//     var targetPath = TargetPath(ctx: ctx)
//     targetPath.push(decl: AnyDeclID(typeAliasId))
//     ctx.urlResolver.resolve(
//       target: .symbol(AnyDeclID(typeAliasId)), filePath: targetPath.url, parent: nil)

//     let res = try! renderTypeAliasPage(ctx: ctx, of: typeAliasId, with: doc)

//     // Assert
//     XCTAssertTrue(res.contains("Vector2"), res)
//     XCTAssertTrue(res.contains("Some summary"), res)
//     XCTAssertTrue(res.contains("Some description"), res)

//     XCTAssertFalse(matchWithWhitespacesInBetween(pattern: [
//             "<h2>",
//             "See Also",
//             "</h2>",
//         ], in: res), res)
//   }
// }
