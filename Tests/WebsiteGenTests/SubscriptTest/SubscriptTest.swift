import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import HyloStandardLibrary
import Stencil
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class SubscriptTest: XCTestCase {
  func test() throws {
    var diagnostics = DiagnosticSet()

    var ast = try AST.loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    // get product type by its id
    let subscriptId = ast.resolveSubscriptDecl(by: "min")!
    let targetId: AnyTargetID = .decl(AnyDeclID(subscriptId))
    let doc = SubscriptDeclDocumentation(
      documentation: CommonFunctionDeclLikeDocumentation(
        common: CommonFunctionLikeDocumentation(
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
          preconditions: [],
          postconditions: [],
          throwsInfo: []
        ),
        parameters: [:],
        genericParameters: [:]
      ),
      yields: []
    )

    var documentation: DocumentationDatabase = .init()
    let _ = documentation.symbols.subscriptDeclDocs.insert(doc, for: subscriptId)

    var targetResolver: TargetResolver = .init()
    let partialResolved = partialResolveDecl(
      documentation, typedProgram, declId: AnyDeclID(subscriptId))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        metaDescription: escapeStringForHTMLAttribute(partialResolved.metaDescription),
        children: partialResolved.children,
        url: URL(fileURLWithPath: "/")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: documentation,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(URL(fileURLWithPath: "/")),
      breadcrumb: [],
      tree: ""
    )

    let stencilContext = try prepareSubscriptPage(context, of: subscriptId)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("subscript min(_:_:)", in: res)
    assertSummary(
      "Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line
    )
    assertDetails(
      "In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file,
      line: #line)

    assertNotContains(res, what: "yields")
    assertNotContains(res, what: "throwsInfo")
    assertNotContains(res, what: "parameters")
    assertNotContains(res, what: "genericParameters")
    assertNotContains(res, what: "seeAlso")
  }
}
