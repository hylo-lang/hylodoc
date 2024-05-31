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
      let program: TypedProgram
      let urlResolver: URLResolver
      let renderers: SymbolDeclRenderers

      init(_ program: TypedProgram, _ urlResolver: URLResolver, _ renderers: SymbolDeclRenderers) {
        self.program = program
        self.urlResolver = urlResolver
        self.renderers = renderers
      }

      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {

        if let d = SubscriptDecl.ID(n) {
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

        if let d = TypeAliasDecl.ID(n) {
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

        if let d = BindingDecl.ID(n) {
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

        if let d = InitializerDecl.ID(n) {
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

        if let d = FunctionDecl.ID(n) {
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

        if let d = MethodDecl.ID(n) {
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

        if let d = ProductTypeDecl.ID(n) {
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
        }

        return true
      }
    }

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast),
      inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false }
    )

    let urlResolver = URLResolver(baseUrl: AbsolutePath(pathString: ""))

    let renderers: SymbolDeclRenderers = .init(
      program: typedProgram, resolver: urlResolver)

    var visitor = ASTWalkingVisitor(typedProgram, urlResolver, renderers)

    print("=========")
    ast.walk(moduleId, notifying: &visitor)
    print("=========")
  }
}
