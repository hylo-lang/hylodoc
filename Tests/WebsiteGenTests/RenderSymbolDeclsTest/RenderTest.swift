import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderSymbolDeclsTest: XCTestCase {
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
      var listOfProductTypes: [ProductTypeDecl.ID] = []

      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
        if let d = ProductTypeDecl.ID(n) {
          listOfProductTypes.append(d)
        }
        return true
      }
    }
    var visitor = ASTWalkingVisitor()
    ast.walk(moduleId, notifying: &visitor)

    print("=========")

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast),
      inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    let db: DocumentationDatabase = .init()
    let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))

    let ctx = GenerationContext(
      documentation: db,
      stencil: stencil,
      typedProgram: typedProgram,
      urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
    )

    for d in visitor.listOfProductTypes {

      let simpleRenderer = SimpleSymbolDecRenderer.init(
        program: ctx.typedProgram, resolver: ctx.urlResolver)
      let navigationRenderer = NavigationSymbolDecRenderer.init(
        program: ctx.typedProgram, resolver: ctx.urlResolver)
      let inlineRender = DetailedInlineSymbolDeclRenderer.init(
        program: ctx.typedProgram, resolver: ctx.urlResolver)
      let blockRender = DetailedBlockSymbolDeclRenderer.init(
        program: ctx.typedProgram, resolver: ctx.urlResolver)

      let productType: ProductTypeDecl = ctx.typedProgram.ast[d]

      for m in productType.members {
        if let d = TypeAliasDecl.ID(m) {
          print("<h1>[TYPE ALIAS]</h1>")
          print("<h3>simple:</h3>")
          print(simpleRenderer.renderTypeAliasDecl(d))
          print("<h3>navigation:</h3>")
          print(navigationRenderer.renderTypeAliasDecl(d))
          print("<h3>inline:</h3>")
          print(inlineRender.renderTypeAliasDecl(d))
          print("<h3>block:</h3>")
          print(blockRender.renderTypeAliasDecl(d))
          print("<hr>")
        }

        if let d = BindingDecl.ID(m) {
          print("<h1>[BINDING]</h1>")
          print("<h3>simple:</h3>")
          print(simpleRenderer.renderBindingDecl(d))
          print("<h3>navigation:</h3>")
          print(navigationRenderer.renderBindingDecl(d))
          print("<h3>inline:</h3>")
          print(inlineRender.renderBindingDecl(d))
          print("<h3>block:</h3>")
          print(blockRender.renderBindingDecl(d))
          print("<hr>")
        }

        if let d = InitializerDecl.ID(m) {
          print("<h1>[INITIALIZER]</h1>")
          print("<h3>simple:</h3>")
          print(simpleRenderer.renderInitializerDecl(d))
          print("<h3>navigation:</h3>")
          print(navigationRenderer.renderInitializerDecl(d))
          print("<h3>inline:</h3>")
          print(inlineRender.renderInitializerDecl(d))
          print("<h3>block:</h3>")
          print(blockRender.renderInitializerDecl(d))
          print("<hr>")
        }

        if let d = FunctionDecl.ID(m) {
          print("<h1>[FUNCTION]</h1>")
          print("<h3>simple:</h3>")
          print(simpleRenderer.renderFunctionDecl(d))
          print("<h3>navigation:</h3>")
          print(navigationRenderer.renderFunctionDecl(d))
          print("<h3>inline:</h3>")
          print(inlineRender.renderFunctionDecl(d))
          print("<h3>block:</h3>")
          print(blockRender.renderFunctionDecl(d))
          print("<hr>")
        }
      }

      print("<h1>[PRODUCT TYPE]</h1>")
      print("<h3>simple:</h3>")
      print(simpleRenderer.renderProductTypeDecl(d))
      print("<h3>navigation:</h3>")
      print(navigationRenderer.renderProductTypeDecl(d))
      print("<h3>inline:</h3>")
      print(inlineRender.renderProductTypeDecl(d))
      print("<h3>block:</h3>")
      print(blockRender.renderProductTypeDecl(d))
      print("<hr>")

      print("=========")
    }
  }
}
