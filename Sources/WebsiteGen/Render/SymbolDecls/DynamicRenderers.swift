import Foundation
import FrontEnd

/// Dynamic rendering of declarations using the resolved documentation to refer to other declarations in a symbols signature
public protocol DynamicSymbolDeclRenderer {
  static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID
  ) -> String
  static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID
  ) -> String
  static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: ProductTypeDecl.ID
  ) -> String
  static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: BindingDecl.ID
  ) -> String
  static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: InitializerDecl.ID
  ) -> String
  static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FunctionDecl.ID
  ) -> String
  static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: MethodDecl.ID
  ) -> String
  static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: SubscriptDecl.ID
  ) -> String
}

public struct InlineSymbolDeclRenderer: DynamicSymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID
  ) -> String {
    return renderDetailedTrait(ctx, n, true)
  }

  public static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, true)
  }

  public static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.ProductTypeDecl.ID
  ) -> String {
    return renderDetailedProductType(ctx, n, true)
  }

  public static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.BindingDecl.ID
  )
    -> String
  {
    return renderDetailedBinding(ctx, n, true)
  }

  public static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.InitializerDecl.ID
  ) -> String {
    return renderDetailedInitializer(ctx, n, true)
  }

  public static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.FunctionDecl.ID
  )
    -> String
  {
    return renderDetailedFunction(ctx, n, true)
  }

  public static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.MethodDecl.ID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, true)
  }

  public static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.SubscriptDecl.ID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, true)
  }
}

public struct BlockSymbolDeclRenderer: DynamicSymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID
  ) -> String {
    return renderDetailedTrait(ctx, n, false)
  }

  public static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, false)
  }

  public static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: ProductTypeDecl.ID
  ) -> String {
    return renderDetailedProductType(ctx, n, false)
  }

  public static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: BindingDecl.ID
  ) -> String {
    return renderDetailedBinding(ctx, n, false)
  }

  public static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: InitializerDecl.ID
  )
    -> String
  {
    return renderDetailedInitializer(ctx, n, false)
  }

  public static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FunctionDecl.ID
  ) -> String {
    return renderDetailedFunction(ctx, n, false)
  }

  public static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.MethodDecl.ID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, false)
  }

  public static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.SubscriptDecl.ID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, false)
  }
}
