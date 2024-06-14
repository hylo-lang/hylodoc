import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest
import TestUtils

@testable import FrontEnd
@testable import WebsiteGen

final class FunctionTest: XCTestCase {
  func test() {
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
            tracingInferenceIf: { (_, _) in false })

        var ctx = GenerationContext(
            documentation: .init(),
            stencil: createDefaultStencilEnvironment(),
            typedProgram: typedProgram,
            urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
            htmlGenerator: CustomHTMLGenerator(),
            tree: []
        )

    // get product type by its id
    let functionId = ast.resolveFunc(by: "id")!
    let fDoc = FunctionDocumentation(
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
                    seeAlso: [
                        .document([
                        .paragraph(
                            Text(
                            "And then he ran into my first see also."
                            ))
                        ]),
                        .document([
                        .paragraph(
                            Text(
                            "He ran into my second see also 10 times..."
                            ))
                        ]),
                    ]
                ),
                preconditions: [],
                postconditions: [],
                throwsInfo: []
            ),
            parameters: [:],
            genericParameters: [:]
        ),
        returns: []
    )

    var targetPath = TargetPath(ctx: ctx)
    targetPath.push(decl: AnyDeclID(functionId))
    ctx.urlResolver.resolve(target: .symbol(AnyDeclID(functionId)), filePath: targetPath.url, parent: nil)

    let res = try! renderFunctionPage(ctx: &ctx, of: functionId, with: fDoc)

    assertPageTitle("fun id(_:)", in: res, file: #file, line: #line)
    assertSummary("Carving up a summary for dinner, minding my own business.", in: res, file: #file, line: #line)
    assertDetails("In storms my husband Wilbur in a jealous description. He was crazy!", in: res, file: #file, line: #line)
    assertNotContains(res, what: "preconditions", file: #file, line: #line)
    assertNotContains(res, what: "postconditions", file: #file, line: #line)
    assertNotContains(res, what: "returns", file: #file, line: #line)
    assertNotContains(res, what: "throwsInfo", file: #file, line: #line)
    assertNotContains(res, what: "parameters", file: #file, line: #line)
    assertNotContains(res, what: "genericParameters", file: #file, line: #line)
    assertListExistAndCount(id: "seeAlso", count: 2, in: res, file: #file, line: #line)

  }
}
