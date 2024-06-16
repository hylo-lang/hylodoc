import Foundation
import FrontEnd

/// Dynamic rendering of declarations using the resolved documentation to refer to other declarations in a symbols signature
public protocol DynamicSymbolDeclRenderer {
  static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: ProductTypeDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: BindingDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: InitializerDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FunctionDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: MethodDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
  static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: SubscriptDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String
}

public struct InlineSymbolDeclRenderer: DynamicSymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTrait(ctx, n, true, referrenceFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, true, referrenceFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.ProductTypeDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedProductType(ctx, n, true, referrenceFrom)
  }

  public static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.BindingDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedBinding(ctx, n, true, referrenceFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.InitializerDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedInitializer(ctx, n, true, referrenceFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.FunctionDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedFunction(ctx, n, true, referrenceFrom)
  }

  public static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.MethodDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, true, referrenceFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, true, referrenceFrom)
  }
}

public struct BlockSymbolDeclRenderer: DynamicSymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: DocumentationContext, _ n: TraitDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTrait(ctx, n, false, referrenceFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, false, referrenceFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: DocumentationContext, _ n: ProductTypeDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedProductType(ctx, n, false, referrenceFrom)
  }

  public static func renderBindingDecl(
    _ ctx: DocumentationContext, _ n: BindingDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedBinding(ctx, n, false, referrenceFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: DocumentationContext, _ n: InitializerDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedInitializer(ctx, n, false, referrenceFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: DocumentationContext, _ n: FunctionDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedFunction(ctx, n, false, referrenceFrom)
  }

  public static func renderMethodDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.MethodDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, false, referrenceFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: DocumentationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, false, referrenceFrom)
  }
}
