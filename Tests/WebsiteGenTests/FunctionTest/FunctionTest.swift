// import DocumentationDB
// import Foundation
// import FrontEnd
// import MarkdownKit
// import PathWrangler
// import StandardLibraryCore
// import Stencil
// import XCTest

// @testable import FrontEnd
// @testable import WebsiteGen

// final class FunctionTest: XCTestCase {
//   func test() {
//     var diagnostics = DiagnosticSet()

//     var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

//     // We don't really read anything from here right now, we will the documentation database manually
//     let libraryPath = URL(fileURLWithPath: #filePath)
//       .deletingLastPathComponent()
//       .appendingPathComponent("TestHyloFunction")

//     // The module whose Hylo files were given on the command-line
//     let moduleId = try! ast.makeModule(
//       "TestHyloFunction",
//       sourceCode: sourceFiles(in: [libraryPath]),
//       builtinModuleAccess: true,
//       diagnostics: &diagnostics
//     )

//     struct ASTWalkingVisitor: ASTWalkObserver {
//       var listOfProductTypes: [FunctionDecl.ID] = []

//       mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
//         // pattern match the type of node:
//         if let d = FunctionDecl.ID(n) {
//           listOfProductTypes.append(d)
//         }
//         return true
//       }
//     }
//     var visitor = ASTWalkingVisitor()
//     ast.walk(moduleId, notifying: &visitor)

//     let typedProgram = try! TypedProgram(
//       annotating: ScopedProgram(ast), inParallel: false,
//       reportingDiagnosticsTo: &diagnostics,
//       tracingInferenceIf: { (_, _) in false })

//     var ctx = GenerationContext(
//       documentation: .init(),
//       stencil: createDefaultStencilEnvironment(),
//       typedProgram: typedProgram,
//       urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
//     )

//     //Verify we get any id at all
//     XCTAssertTrue(visitor.listOfProductTypes.count > 0)

//     // get product type by its id
//     let functionId = visitor.listOfProductTypes[0]
//     let fDoc = FunctionDocumentation(
//       documentation: CommonFunctionDocumentation(
//         common: GeneralDescriptionFields(
//           summary: .document([
//             .paragraph(
//               Text(
//                 "Carving up a summary for dinner, minding my own business."
//               ))
//           ]),
//           description: .document([
//             .paragraph(
//               Text(
//                 "In storms my husband Wilbur in a jealous description. He was crazy!"
//               ))
//           ]),
//           seeAlso: [
//             .document([
//               .paragraph(
//                 Text(
//                   "And then he ran into my first see also."
//                 ))
//             ]),
//             .document([
//               .paragraph(
//                 Text(
//                   "He ran into my second see also 10 times..."
//                 ))
//             ]),
//           ]
//         ),
//         preconditions: [],
//         postconditions: [],
//         returns: nil,
//         throwsInfo: nil,
//         parameters: [:],
//         genericParameters: [:]
//       )
//     )

// // get product type by its id
// let functionId = visitor.listOfProductTypes[0]
// let fDoc = FunctionDocumentation(
//   documentation: CommonFunctionDeclLikeDocumentation(
//     common: CommonFunctionLikeDocumentation(
//       common: GeneralDescriptionFields(
//       summary: .document([
//         .paragraph(
//           Text(
//             "Carving up a summary for dinner, minding my own business."
//           ))
//       ]),
//       description: .document([
//         .paragraph(
//           Text(
//             "In storms my husband Wilbur in a jealous description. He was crazy!"
//           ))
//       ]),
//       seeAlso: [
//         .document([
//           .paragraph(
//             Text(
//               "And then he ran into my first see also."
//             ))
//         ]),
//         .document([
//           .paragraph(
//             Text(
//               "He ran into my second see also 10 times..."
//             ))
//         ]),
//       ]
//     ),
//       preconditions: [],
//       postconditions: [],
//       throwsInfo: []
//     ),
//     parameters: [:],
//     genericParameters: [:]
//   ),
//   returns: []
// )

//     let res = try! renderFunctionPage(ctx: ctx, of: functionId, with: fDoc)
//     let _ = res
//     // XCTAssertTrue(res.contains("fun exampleFunction"), res)
//     // XCTAssertTrue(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<pre>",
//     //       "public fun examleFunction() {",
//     //       "return",
//     //       "}",
//     //       "</pre>",
//     //     ], in: res), res)
//     // XCTAssertTrue(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h4>",
//     //       "<p>",
//     //       "Carving up a summary for dinner, minding my own business.",
//     //       "</p>",
//     //       "</h4>",
//     //     ], in: res), res)
//     // XCTAssertTrue(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Details",
//     //       "</h1>",
//     //       "<p>",
//     //       "In storms my husband Wilbur in a jealous description. He was crazy!",
//     //       "</p>",
//     //     ], in: res), res)
//     // XCTAssertTrue(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "See Also",
//     //       "</h1>",
//     //       "<ul>",
//     //       "<li>",
//     //       "<p>",
//     //       "And then he ran into my first see also.",
//     //       "</p>",
//     //       "</li>",
//     //       "<li>",
//     //       "<p>",
//     //       "He ran into my second see also 10 times...",
//     //       "</p>",
//     //       "</li>",
//     //       "</ul>",
//     //     ], in: res), res)

//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Preconditions",
//     //       "</h1>",
//     //     ], in: res), res)
//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Postconditions",
//     //       "</h1>",
//     //     ], in: res), res)
//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Returns",
//     //       "</h1>",
//     //     ], in: res), res)
//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Throws Info",
//     //       "</h1>",
//     //     ], in: res), res)
//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Parameters",
//     //       "</h1>",
//     //     ], in: res), res)
//     // XCTAssertFalse(
//     //   matchWithWhitespacesInBetween(
//     //     pattern: [
//     //       "<h1>",
//     //       "Generic Parameters",
//     //       "</h1>",
//     //     ], in: res), res)
//   }
// }
