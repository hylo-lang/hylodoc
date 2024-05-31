import Foundation
import FrontEnd

protocol SymbolDeclRenderer {
  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String
}

struct SimpleSymbolDecRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(program: TypedProgram, resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderSimpleTypeAlias(program, n, true)
  }
}
