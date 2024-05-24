import Foundation
import FrontEnd

public func loadStandardLibraryCore(diagnostics: inout DiagnosticSet) -> AST {
  let url = Bundle.module.url(forResource: "StandardLibraryCoreResource", withExtension: nil)!

  /// An instance that includes just the standard library.
  var ast = AST(ConditionalCompilationFactors(freestanding: true))

  // Load standard library core
  ast.coreLibrary = try! ast.makeModule(
    "Hylo",
    sourceCode: sourceFiles(in: [url]),
    builtinModuleAccess: true,
    diagnostics: &diagnostics
  )
  ast.coreTraits = .init(ast)
  return ast
}
