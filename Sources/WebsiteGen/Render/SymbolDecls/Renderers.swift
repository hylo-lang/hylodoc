import Foundation
import FrontEnd

public protocol SymbolDeclRenderer {
  static func renderTraitDecl(
    _ ctx: GenerationContext, _ n: TraitDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderTypeAliasDecl(
    _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderProductTypeDecl(
    _ ctx: GenerationContext, _ n: ProductTypeDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderBindingDecl(
    _ ctx: GenerationContext, _ n: BindingDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderInitializerDecl(
    _ ctx: GenerationContext, _ n: InitializerDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderFunctionDecl(
    _ ctx: GenerationContext, _ n: FunctionDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderMethodDecl(
    _ ctx: GenerationContext, _ n: MethodDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
  static func renderSubscriptDecl(
    _ ctx: GenerationContext, _ n: SubscriptDecl.ID, _ referringFrom: AnyTargetID
  ) -> String
}

public struct SimpleSymbolDeclRenderer: SymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: GenerationContext, _ n: TraitDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleTrait(ctx, n, true, referringFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleTypeAlias(ctx, n, true, referringFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.ProductTypeDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleProductType(ctx, n, true, referringFrom)
  }

  public static func renderBindingDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.BindingDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleBinding(ctx, n, true, referringFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.InitializerDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleInitializer(ctx, n, true, referringFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.FunctionDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleFunction(ctx, n, true, referringFrom)
  }

  public static func renderMethodDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.MethodDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleMethod(ctx, n, true, referringFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleSubscript(ctx, n, true, referringFrom)
  }
}

public struct NavigationSymbolDecRenderer: SymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: GenerationContext, _ n: TraitDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleTrait(ctx, n, false, referringFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleTypeAlias(ctx, n, false, referringFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.ProductTypeDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleProductType(ctx, n, false, referringFrom)
  }

  public static func renderBindingDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.BindingDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleBinding(ctx, n, false, referringFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.InitializerDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleInitializer(ctx, n, false, referringFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.FunctionDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleFunction(ctx, n, false, referringFrom)
  }

  public static func renderMethodDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.MethodDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleMethod(ctx, n, false, referringFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referringFrom: AnyTargetID
  ) -> String {
    return renderSimpleSubscript(ctx, n, false, referringFrom)
  }
}

public struct InlineSymbolDeclRenderer: SymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: GenerationContext, _ n: TraitDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTrait(ctx, n, true, referrenceFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, true, referrenceFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.ProductTypeDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedProductType(ctx, n, true, referrenceFrom)
  }

  public static func renderBindingDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.BindingDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedBinding(ctx, n, true, referrenceFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.InitializerDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedInitializer(ctx, n, true, referrenceFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.FunctionDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedFunction(ctx, n, true, referrenceFrom)
  }

  public static func renderMethodDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.MethodDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, true, referrenceFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, true, referrenceFrom)
  }
}

public struct BlockSymbolDeclRenderer: SymbolDeclRenderer {

  public static func renderTraitDecl(
    _ ctx: GenerationContext, _ n: TraitDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTrait(ctx, n, false, referrenceFrom)
  }

  public static func renderTypeAliasDecl(
    _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedTypeAlias(ctx, n, false, referrenceFrom)
  }

  public static func renderProductTypeDecl(
    _ ctx: GenerationContext, _ n: ProductTypeDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedProductType(ctx, n, false, referrenceFrom)
  }

  public static func renderBindingDecl(
    _ ctx: GenerationContext, _ n: BindingDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedBinding(ctx, n, false, referrenceFrom)
  }

  public static func renderInitializerDecl(
    _ ctx: GenerationContext, _ n: InitializerDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedInitializer(ctx, n, false, referrenceFrom)
  }

  public static func renderFunctionDecl(
    _ ctx: GenerationContext, _ n: FunctionDecl.ID, _ referrenceFrom: AnyTargetID
  ) -> String {
    return renderDetailedFunction(ctx, n, false, referrenceFrom)
  }

  public static func renderMethodDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.MethodDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedMethod(ctx, n, false, referrenceFrom)
  }

  public static func renderSubscriptDecl(
    _ ctx: GenerationContext, _ n: FrontEnd.SubscriptDecl.ID, _ referrenceFrom: AnyTargetID
  )
    -> String
  {
    return renderDetailedSubscript(ctx, n, false, referrenceFrom)
  }
}
