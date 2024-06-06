import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class BindingTest: XCTestCase {
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

    var ctx = GenerationContext(
      documentation: .init(),
      stencil: createDefaultStencilEnvironment(),
      typedProgram: typedProgram,
      urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
    )

    //Verify we get any id at all
    XCTAssertTrue(visitor.listOfProductTypes.count > 0)

    // get product type by its id
    let bindingId = visitor.listOfProductTypes[0]
    let bindingDoc = BindingDocumentation(
      common: GeneralDescriptionFields(
        summary: .document([
          .paragraph(
            Text(
              "Carving up a summary for dinner, minding my own business."
            ))
        ]),
        description: .document([
          .paragraph(
            Text(
              "In storms my husband Wilbur in a jealous description. He was crazy!"
            ))
        ]),
        seeAlso: []
      ),
      invariants: [
        Invariant(description: .document([.paragraph(Text("Invariants are cool"))]))
      ]
    )

    var targetPath = TargetPath(ctx: ctx)
    targetPath.push(decl: AnyDeclID(bindingId))
    ctx.urlResolver.resolve(
      target: .symbol(AnyDeclID(bindingId)), filePath: targetPath.url, parent: nil)

    let res = try! renderBindingPage(ctx: ctx, of: bindingId, with: bindingDoc)

    XCTAssertTrue(res.contains("Binding"), res)
    XCTAssertTrue(
      matchWithWhitespacesInBetween(
        pattern: [
          "<pre>",
          "let x = 5",
          "</pre>",
        ], in: res), res)
    XCTAssertTrue(
      matchWithWhitespacesInBetween(
        pattern: [
          "<p>",
          "Carving up a summary for dinner, minding my own business.",
          "</p>",
        ], in: res), res)
    XCTAssertTrue(
      matchWithWhitespacesInBetween(
        pattern: [
          "<h1>",
          "Details",
          "</h1>",
          "<p>",
          "In storms my husband Wilbur in a jealous description. He was crazy!",
          "</p>",
        ], in: res), res)
    XCTAssertTrue(
      matchWithWhitespacesInBetween(
        pattern: [
          "<h1>",
          "Invariants",
          "</h1>",
          "<ul>",
          "<li>",
          "<p>",
          "Invariants are cool",
          "</p>",
          "</li>",
          "</ul>",
        ], in: res), res)

    XCTAssertFalse(
      matchWithWhitespacesInBetween(
        pattern: [
          "<h1>",
          "See Also",
          "</h1>",
        ], in: res), res)
  }
}
