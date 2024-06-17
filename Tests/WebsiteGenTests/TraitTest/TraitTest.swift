import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class TraitTest: XCTestCase {
  func test() throws {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

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
    let traitId = ast.resolveTrait(by: "Shape")!
    let targetId: AnyTargetID = .decl(AnyDeclID(traitId))
    let doc = TraitDocumentation(
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

    var documentation: DocumentationDatabase = .init()
    let _ = documentation.symbols.traitDocs.insert(doc, for: traitId)

    var targetResolver: TargetResolver = .init()
    let partialResolved = partialResolveDecl(
      documentation, typedProgram, declId: AnyDeclID(traitId))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children,
        relativePath: RelativePath.current
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: documentation,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: [],
      tree: []
    )

    let stencilContext = try prepareTraitPage(context, of: traitId)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("trait Shape", in: res)
    assertSummary(
      "Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line
    )
    assertDetails(
      "In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file,
      line: #line)
    assertListExistAndCount(id: "invariants", count: 1, in: res)

    // let members = findByID("members", in: res)
    assertSectionsExsistingAndCount(
      [
        "Associated Types": 0,
        "Associated Values": 0,
        "Type Aliases": 0,
        "Bindings": 0,
        "Operators": 0,
        "Functions": 2,
        "Methods": 0,
        "Subscripts": 0,
        "Initializers": 0,
        "Traits": 0,
        "Product Types": 0,
      ],
      // in: members,
      in: res,
      file: #file, line: #line
    )

    assertNotContains(res, what: "seeAlso")
  }
}
