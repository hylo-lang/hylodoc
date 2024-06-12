import DocumentationDB
import FrontEnd
import PathWrangler

public struct TreeItem {
  let id: AnyTargetID
  let name: String
  let typeClass: String
  let relativePath: RelativePath
  let children: [TreeItem]
}

/// Get the navigation name of a target
public func navigationNameOfTarget(ctx: GenerationContext, target: AnyTargetID) -> String {
  switch target {
  case .asset(let assetId):
    return displayNameOfAsset(ctx: ctx, asset: assetId)
  case .symbol(let symbolId):
    return navigationNameOfSymbol(ctx: ctx, symbol: symbolId)
  case .empty:
    return ""
  }
}

/// Get the navigation name of a symbol
public func navigationNameOfSymbol(ctx: GenerationContext, symbol: AnyDeclID) -> String {
  switch symbol.kind {
  //case AssociatedTypeDecl.self
  //case AssociatedValueDecl.self
  case TypeAliasDecl.self:
    let id = TypeAliasDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderTypeAliasDecl(ctx, id, .empty)
  case BindingDecl.self:
    let id = BindingDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderBindingDecl(ctx, id, .empty)
  //case OperatorDecl.self
  case FunctionDecl.self:
    let id = FunctionDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderFunctionDecl(ctx, id, .empty)
  case MethodDecl.self:
    let id = MethodDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderMethodDecl(ctx, id, .empty)
  //case MethodImpl.self
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderSubscriptDecl(ctx, id, .empty)
  //case SubscriptImpl.self
  case InitializerDecl.self:
    let id = InitializerDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderInitializerDecl(ctx, id, .empty)
  case TraitDecl.self:
    let id = TraitDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderTraitDecl(ctx, id, .empty)
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(symbol)!
    return NavigationSymbolDecRenderer.renderProductTypeDecl(ctx, id, .empty)
  default:
    return ""
  }
}

// Get the class used for the navigation item
public func navigationClassOfTarget(targetId: AnyTargetID) -> String {
  return switch targetId {
  case .asset(let assetId):
    switch assetId {
    case .folder(_):
      "folder"  // folder icon
    case .article(_):
      "article"  // article icon
    case .sourceFile(_):
      "source-file"  // source-file icon
    default:
      ""  // has no icon
    }
  default:
    "symbol"  // has no icon, used to distinct between symbols and assets
  }
}

// Create a tree item for a target
public func createTreeItem(ctx: GenerationContext, targetId: AnyTargetID, children: [TreeItem])
  -> TreeItem
{
  return TreeItem(
    id: targetId,
    name: navigationNameOfTarget(ctx: ctx, target: targetId),
    typeClass: navigationClassOfTarget(targetId: targetId),
    relativePath: ctx.urlResolver.refer(from: .empty, to: targetId)
      ?? RelativePath(pathString: "."),
    children: children
  )
}

/// Create a tree item from an asset
public func treeItemFromAsset(ctx: GenerationContext, assetId: AnyAssetID) -> TreeItem {
  switch assetId {
  case .folder(let id):
    let folder = ctx.documentation.assets.folders[id]!
    return createTreeItem(
      ctx: ctx,
      targetId: .asset(assetId),
      children: folder.children
        .filter { folder.documentation == nil || $0 != .article(folder.documentation!) }
        .map { treeItemFromAsset(ctx: ctx, assetId: $0) }
    )
  case .sourceFile(let id):
    // Traverse children
    let sourceFile = ctx.documentation.assets.sourceFiles[id]!
    return createTreeItem(
      ctx: ctx,
      targetId: .asset(assetId),
      children: ctx.typedProgram.ast[sourceFile.translationUnit]!.decls
        .map { treeItemFromSymbol(ctx: ctx, symbolId: $0) }
        .filter { $0 != nil }
        .map { $0! }
    )
  default:
    return createTreeItem(
      ctx: ctx,
      targetId: .asset(assetId),
      children: []
    )
  }
}

/// Create a tree item from a symbol
public func treeItemFromSymbol(ctx: GenerationContext, symbolId: AnyDeclID) -> TreeItem? {
  switch symbolId.kind {
  case AssociatedTypeDecl.self,
    AssociatedValueDecl.self,
    TypeAliasDecl.self,
    BindingDecl.self,
    OperatorDecl.self,
    FunctionDecl.self,
    MethodImpl.self,
    SubscriptImpl.self,
    InitializerDecl.self,
    MethodDecl.self,
    SubscriptDecl.self:
    return createTreeItem(
      ctx: ctx,
      targetId: .symbol(symbolId),
      children: []
    )
  case TraitDecl.self:
    let id = TraitDecl.ID(symbolId)!
    let decl = ctx.typedProgram.ast[id]!

    return createTreeItem(
      ctx: ctx,
      targetId: .symbol(symbolId),
      children: decl.members
        .map { treeItemFromSymbol(ctx: ctx, symbolId: $0) }
        .filter { $0 != nil }
        .map { $0! }
    )
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(symbolId)!
    let decl = ctx.typedProgram.ast[id]!

    return createTreeItem(
      ctx: ctx,
      targetId: .symbol(symbolId),
      children: decl.members
        .map { treeItemFromSymbol(ctx: ctx, symbolId: $0) }
        .filter { $0 != nil }
        .map { $0! }
    )
  default:
    return nil
  }
}
