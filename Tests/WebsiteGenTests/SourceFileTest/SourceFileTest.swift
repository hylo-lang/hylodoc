import DocExtractor
import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

func assetNameIs(_ name: String, _ assets: AssetStore) -> ((AnyAssetID) -> Bool) {
  { assets[$0]?.location.lastPathComponent == name }
}

final class SourceFileTest: XCTestCase {

  // check renderSourceFilePage function using SourceFileAsset created manually
  func test() throws {

    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)
    let myModuleId = try! ast.makeModule(
      "MyModule",
      sourceCode: [
        SourceFile(
          synthesizedText: """

            """, named: "sourceFileExample.hylo")
      ], builtinModuleAccess: false, diagnostics: &diagnostics)

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    let translationUnitId = ast[myModuleId].sources.first!

    let sourceFile = SourceFileAsset(
      location: URL(string: "root/Folder1/sourceFileExample.hylo")!,
      generalDescription: GeneralDescriptionFields(
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
        seeAlso: [
          .document([.paragraph(Text("And then he ran into my first see also."))]),
          .document([.paragraph(Text("He ran into my second see also 10 times..."))]),
        ]
      ),
      translationUnit: translationUnitId
    )

    var db = DocumentationDatabase.init()
    let sourceFileID = db.assets.sourceFiles.insert(sourceFile, for: translationUnitId)
    let targetId: AnyTargetID = .asset(.sourceFile(sourceFileID))

    var targetResolver: TargetResolver = .init()
    let partialResolved = partialResolveAsset(db, typedProgram, assetId: .sourceFile(sourceFileID))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        parent: nil,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children,
        relativePath: RelativePath.current
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: []
    )

    let stencilContext = try prepareSourceFilePage(context, of: sourceFileID)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("sourceFileExample.hylo", in: res, file: #file, line: #line)
    assertSummary(
      "Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line
    )
    assertDetails(
      "In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file,
      line: #line)
    assertListExistAndCount(id: "seeAlso", count: 2, in: res, file: #file, line: #line)

    assertNotContains(res, what: "members", file: #file, line: #line)
  }
}
