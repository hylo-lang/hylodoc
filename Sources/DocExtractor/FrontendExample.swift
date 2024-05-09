import DocumentationDB
import Down
import Foundation
import FrontEnd

/// a function that returns if a number is even or not
public func isEven(number: Int) -> Bool {
  return number % 2 == 0
}

public func extractData() {
  let productName = "myProduct"

  let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("ExampleModule")

  /// An instance that includes just the standard library.
  var ast = AST(ConditionalCompilationFactors())

  var diagnostics = DiagnosticSet()

  // The module whose Hylo files were given on the command-line
  let _ = try! ast.makeModule(
    productName,
    sourceCode: sourceFiles(in: [libraryPath]),
    builtinModuleAccess: true,
    diagnostics: &diagnostics
  )

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

  // get product type by its id
  for productTypeId in visitor.listOfProductTypes {
    let _ = ast[productTypeId]
    // print(productType)
  }

  // let typedProgram = try! TypedProgram(
  //   annotating: ScopedProgram(ast), inParallel: false,
  //   reportingDiagnosticsTo: &diagnostics,
  //   tracingInferenceIf: shouldTraceInference)

}

private func shouldTraceInference(_ n: AnyNodeID, _ p: TypedProgram) -> Bool {
  return true
}
