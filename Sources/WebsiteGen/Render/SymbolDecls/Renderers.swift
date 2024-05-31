import Foundation
import FrontEnd

protocol SymbolDeclRenderer {
  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String
  func renderProductTypeDecl(_ n: ProductTypeDecl.ID) -> String
  func renderBindingDecl(_ n: BindingDecl.ID) -> String
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

  func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderSimpleProductType(program, n, true)
  }

  func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderSimpleBinding(program, n, true)
  }
}
