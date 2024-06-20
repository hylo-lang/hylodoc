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

final class OperatorTest: XCTestCase {
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
    let operatorId = ast.resolveOperator()!.first!
    let targetId: AnyTargetID = .decl(AnyDeclID(operatorId))
    let doc = OperatorDocumentation(
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
      ))

    var documentation: DocumentationDatabase = .init()
    let _ = documentation.symbols.operatorDocs.insert(doc, for: operatorId)

    var targetResolver: TargetResolver = .init()
    let partialResolved = partialResolveDecl(
      documentation, typedProgram, declId: AnyDeclID(operatorId))
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

    let stencilContext = try prepareOperatorPage(context, of: operatorId)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("public operator infix", in: res)
    assertSummary(
      "Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line
    )
    assertDetails(
      "In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file,
      line: #line)

    assertNotContains(res, what: "seeAlso")
  }
}
