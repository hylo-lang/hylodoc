import Foundation
import FrontEnd

/// An extension to the AST that allows to easily load the standard library.
extension AST {
  public static var standardLibraryModulePath: URL {
    Bundle.module.url(forResource: "Sources", withExtension: nil)!
  }

  public static var standardLibraryCoreModulePath: URL {
    standardLibraryModulePath.appendingPathComponent("Core")
  }

  /// Loads only the core of the standard library into an AST.
  public static func loadStandardLibraryCore(diagnostics: inout DiagnosticSet) throws -> AST {
    try loadStdLibCommon(url: AST.standardLibraryCoreModulePath, diagnostics: &diagnostics)
  }

  /// Loads the entire standard library into an AST.
  public static func loadStandardLibrary(diagnostics: inout DiagnosticSet) throws -> AST {
    try loadStdLibCommon(url: AST.standardLibraryModulePath, diagnostics: &diagnostics)
  }
}

/// Common code to load a module that has access to builtins and contains the core traits.
private func loadStdLibCommon(url: URL, diagnostics: inout DiagnosticSet) throws -> AST {
  // Create an empty AST
  var ast = AST(ConditionalCompilationFactors(freestanding: true))

  // Load the standard library module
  ast.coreLibrary = try! ast.makeModule(
    "Hylo",
    sourceCode: sourceFiles(in: [url]),
    builtinModuleAccess: true,
    diagnostics: &diagnostics
  )

  // Loads the core trait data structures from the currently imported module.
  ast.coreTraits = .init(ast)
  return ast
}
