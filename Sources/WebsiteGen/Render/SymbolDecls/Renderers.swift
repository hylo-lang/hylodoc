import Foundation
import FrontEnd

public protocol SymbolDeclRenderer {
  func renderTraitDecl(_ n: TraitDecl.ID) -> String
  func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String
  func renderProductTypeDecl(_ n: ProductTypeDecl.ID) -> String
  func renderBindingDecl(_ n: BindingDecl.ID) -> String
  func renderInitializerDecl(_ n: InitializerDecl.ID) -> String
  func renderFunctionDecl(_ n: FunctionDecl.ID) -> String
  func renderMethodDecl(_ n: MethodDecl.ID) -> String
  func renderSubscriptDecl(_ n: SubscriptDecl.ID) -> String
}

public struct SymbolDeclRenderers {
  public let simple: SimpleSymbolDecRenderer
  public let navigation: NavigationSymbolDecRenderer
  public let inline: DetailedInlineSymbolDeclRenderer
  public let block: DetailedBlockSymbolDeclRenderer

  public init(program: TypedProgram, resolver: URLResolver) {
    simple = .init(program, resolver)
    navigation = .init(program, resolver)
    inline = .init(program, resolver)
    block = .init(program, resolver)
  }
}

public struct SimpleSymbolDecRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(_ program: TypedProgram, _ resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  public func renderTraitDecl(_ n: TraitDecl.ID) -> String {
    return renderSimpleTrait(program, n, true)
  }

  public func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderSimpleTypeAlias(program, n, true)
  }

  public func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderSimpleProductType(program, n, true)
  }

  public func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderSimpleBinding(program, n, true)
  }

  public func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return renderSimpleInitializer(program, n, true)
  }

  public func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return renderSimpleFunction(program, n, true)
  }

  public func renderMethodDecl(_ n: FrontEnd.MethodDecl.ID) -> String {
    return renderSimpleMethod(program, n, true)
  }

  public func renderSubscriptDecl(_ n: FrontEnd.SubscriptDecl.ID) -> String {
    return renderSimpleSubscript(program, n, true)
  }
}

public struct NavigationSymbolDecRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(_ program: TypedProgram, _ resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  public func renderTraitDecl(_ n: TraitDecl.ID) -> String {
    return renderSimpleTrait(program, n, false)
  }

  public func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderSimpleTypeAlias(program, n, false)
  }

  public func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderSimpleProductType(program, n, false)
  }

  public func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderSimpleBinding(program, n, false)
  }

  public func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return renderSimpleInitializer(program, n, false)
  }

  public func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return renderSimpleFunction(program, n, false)
  }

  public func renderMethodDecl(_ n: FrontEnd.MethodDecl.ID) -> String {
    return renderSimpleMethod(program, n, false)
  }

  public func renderSubscriptDecl(_ n: FrontEnd.SubscriptDecl.ID) -> String {
    return renderSimpleSubscript(program, n, false)
  }
}

public struct DetailedInlineSymbolDeclRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(_ program: TypedProgram, _ resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  public func renderTraitDecl(_ n: TraitDecl.ID) -> String {
    return renderDetailedTrait(program, n, true)
  }

  public func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderDetailedTypeAlias(program, n, true)
  }

  public func renderProductTypeDecl(_ n: FrontEnd.ProductTypeDecl.ID) -> String {
    return renderDetailedProductType(program, n, true)
  }

  public func renderBindingDecl(_ n: FrontEnd.BindingDecl.ID) -> String {
    return renderDetailedBinding(program, n, true)
  }

  public func renderInitializerDecl(_ n: FrontEnd.InitializerDecl.ID) -> String {
    return renderDetailedInitializer(program, n, true)
  }

  public func renderFunctionDecl(_ n: FrontEnd.FunctionDecl.ID) -> String {
    return renderDetailedFunction(program, n, true)
  }

  public func renderMethodDecl(_ n: FrontEnd.MethodDecl.ID) -> String {
    return renderDetailedMethod(program, n, true)
  }

  public func renderSubscriptDecl(_ n: FrontEnd.SubscriptDecl.ID) -> String {
    return renderDetailedSubscript(program, n, true)
  }
}

public struct DetailedBlockSymbolDeclRenderer: SymbolDeclRenderer {
  private let program: TypedProgram
  private let resolver: URLResolver

  public init(_ program: TypedProgram, _ resolver: URLResolver) {
    self.program = program
    self.resolver = resolver
  }

  public func renderTraitDecl(_ n: TraitDecl.ID) -> String {
    return renderDetailedTrait(program, n, false)
  }

  public func renderTypeAliasDecl(_ n: TypeAliasDecl.ID) -> String {
    return renderDetailedTypeAlias(program, n, false)
  }

  public func renderProductTypeDecl(_ n: ProductTypeDecl.ID) -> String {
    return renderDetailedProductType(program, n, false)
  }

  public func renderBindingDecl(_ n: BindingDecl.ID) -> String {
    return renderDetailedBinding(program, n, false)
  }

  public func renderInitializerDecl(_ n: InitializerDecl.ID) -> String {
    return renderDetailedInitializer(program, n, false)
  }

  public func renderFunctionDecl(_ n: FunctionDecl.ID) -> String {
    return renderDetailedFunction(program, n, false)
  }

  public func renderMethodDecl(_ n: FrontEnd.MethodDecl.ID) -> String {
    return renderDetailedMethod(program, n, false)
  }

  public func renderSubscriptDecl(_ n: FrontEnd.SubscriptDecl.ID) -> String {
    return renderDetailedSubscript(program, n, false)
  }
}
