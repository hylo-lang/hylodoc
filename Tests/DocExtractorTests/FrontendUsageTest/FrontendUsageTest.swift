import DocumentationDB
import Foundation
import FrontEnd
import XCTest

final class FrontendUsageTest: XCTestCase {
  func testASTWalking() {
    let libraryPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("ExampleModule")

    /// An instance that includes just the standard library.
    var ast = AST(ConditionalCompilationFactors())

    var diagnostics = DiagnosticSet()

    // The module whose Hylo files were given on the command-line
    let createdModuleId = try! ast.makeModule(
      "ExampleModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let _ = createdModuleId

    struct ASTWalkingVisitor: ASTWalkObserver {
      var listOfProductTypes: [ProductTypeDecl.ID] = []

      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
        // pattern match the type of node:
        if let d = ProductTypeDecl.ID(n) {
          listOfProductTypes.append(d)
        } else if let d = ModuleDecl.ID(n) {
          let moduleInfo = ast[d]
          print("Module found: " + moduleInfo.baseName)
        } else if let d = TranslationUnit.ID(n) {
          let translationUnit = ast[d]
          print("TU found: " + translationUnit.site.file.baseName)
        } else if let d = FunctionDecl.ID(n) {
          let functionDecl = ast[d]
          print("Function found: " + (functionDecl.identifier?.value ?? "*unnamed*"))
        } else if let d = OperatorDecl.ID(n) {
          let operatorDecl = ast[d]
          print("Operator found: " + operatorDecl.name.value)
        } else if let d = VarDecl.ID(n) {
          let varDecl = ast[d]
          print("VarDecl found: " + varDecl.baseName)
        } else if let d = BindingDecl.ID(n) {
          let bindingDecl = ast[d]
          let _ = bindingDecl
          print("BindingDecl found.")
        }
        return true
      }
    }
    var visitor = ASTWalkingVisitor()
    for m in ast.modules {
      ast.walk(m, notifying: &visitor)
    }

    XCTAssertEqual(
      visitor.listOfProductTypes.map { ast[$0].baseName }.sorted(),
      ["A", "InnerType", "MyType"]
    )
  }
}
