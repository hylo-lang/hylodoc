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

      let renderers: SymbolDeclRenderers = .init(
        program: ctx.typedProgram, resolver: ctx.urlResolver)

      let productType: ProductTypeDecl = ctx.typedProgram.ast[d]

      for m in productType.members {
        if let d = SubscriptDecl.ID(m) {
          print("<h1>[SUBSCRIPT]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderSubscriptDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderSubscriptDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderSubscriptDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderSubscriptDecl(d))
          print("<hr>")
        }

        if let d = TypeAliasDecl.ID(m) {
          print("<h1>[TYPE ALIAS]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderTypeAliasDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderTypeAliasDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderTypeAliasDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderTypeAliasDecl(d))
          print("<hr>")
        }

        if let d = BindingDecl.ID(m) {
          print("<h1>[BINDING]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderBindingDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderBindingDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderBindingDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderBindingDecl(d))
          print("<hr>")
        }

        if let d = InitializerDecl.ID(m) {
          print("<h1>[INITIALIZER]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderInitializerDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderInitializerDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderInitializerDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderInitializerDecl(d))
          print("<hr>")
        }

        if let d = FunctionDecl.ID(m) {
          print("<h1>[FUNCTION]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderFunctionDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderFunctionDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderFunctionDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderFunctionDecl(d))
          print("<hr>")
        }

        if let d = MethodDecl.ID(m) {
          print("<h1>[METHOD]</h1>")
          print("<h3>simple:</h3>")
          print(renderers.simple.renderMethodDecl(d))
          print("<h3>navigation:</h3>")
          print(renderers.navigation.renderMethodDecl(d))
          print("<h3>inline:</h3>")
          print(renderers.inline.renderMethodDecl(d))
          print("<h3>block:</h3>")
          print(renderers.block.renderMethodDecl(d))
          print("<hr>")
        }
      }

      print("<h1>[PRODUCT TYPE]</h1>")
      print("<h3>simple:</h3>")
      print(renderers.simple.renderProductTypeDecl(d))
      print("<h3>navigation:</h3>")
      print(renderers.navigation.renderProductTypeDecl(d))
      print("<h3>inline:</h3>")
      print(renderers.inline.renderProductTypeDecl(d))
      print("<h3>block:</h3>")
      print(renderers.block.renderProductTypeDecl(d))
      print("<hr>")

      print("=========")
    }
  }
}
