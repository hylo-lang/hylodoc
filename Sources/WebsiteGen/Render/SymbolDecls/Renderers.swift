import Foundation
import FrontEnd

protocol SymbolDeclRenderer {
  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String
  func renderProductTypeDecl(_ n: ProductTypeDecl.ID) -> String
  func renderBindingDecl(_ n: BindingDecl.ID) -> String
  func renderInitializerDecl(_ n: InitializerDecl.ID) -> String
  func renderFunctionDecl(_ n: FunctionDecl.ID) -> String
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

  func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return renderSimpleInitializer(program, n, true)
  }

  func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return renderSimpleFunction(program, n, true)
  }
}

struct NavigationSymbolDecRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(program: TypedProgram, resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderSimpleTypeAlias(program, n, false)
  }

  func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderSimpleProductType(program, n, false)
  }

  func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderSimpleBinding(program, n, false)
  }

  func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return renderSimpleInitializer(program, n, false)
  }

  func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return renderSimpleFunction(program, n, false)
  }
}

struct DetailedInlineSymbolDeclRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(program: TypedProgram, resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderDetailedTypeAlias(program, n, true)
  }

  func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderDetailedProductType(program, n, true)
  }

  func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderDetailedBinding(program, n, true)
  }

  func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return ""
  }

  func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return ""
  }
}
