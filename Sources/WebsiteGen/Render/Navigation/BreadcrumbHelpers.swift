import DocumentationDB
import Foundation
import FrontEnd
import PathWrangler

/// Generate the breadcrumb tuples for a target
public func breadcrumb(ctx: GenerationContext, target: AnyTargetID) -> [(String, RelativePath)] {
  if case .empty = target {
    return []
  }

  return ctx.urlResolver.pathStack(target: target).map {
    pathTarget in
    (
      displayNameOfTarget(ctx: ctx, target: pathTarget),
      ctx.urlResolver.references[pathTarget]!.path
    )
  }
}

/// Get the display name symbol a target
public func displayNameOfTarget(ctx: GenerationContext, target: AnyTargetID) -> String {
  switch target {
  case .asset(let assetId):
    return displayNameOfAsset(ctx: ctx, asset: assetId)
  case .symbol(let symbolId):
    return displayNameOfSymbol(ctx: ctx, symbol: symbolId)
  case .empty:
    return ""
  }
}

/// Get the display name symbol an asset
public func displayNameOfAsset(ctx: GenerationContext, asset: AnyAssetID) -> String {
  switch asset {
  case .folder(let folderId):
    let folder = ctx.documentation.assets[folderId]!
    return folder.name
  case .sourceFile(let sourceFileId):
    let sourceFile = ctx.documentation.assets[sourceFileId]!
    return sourceFile.name
  case .article(let articleId):
    let article = ctx.documentation.assets[articleId]!
    return article.title ?? article.name
  case .otherFile(let otherId):
    let otherFile = ctx.documentation.assets[otherId]!
    return otherFile.name
  }
}

/// Get the display name symbol a symbol
public func displayNameOfSymbol(ctx: GenerationContext, symbol: AnyDeclID) -> String {
  switch symbol.kind {
  //case AssociatedTypeDecl.self
  //case AssociatedValueDecl.self
  case TypeAliasDecl.self:
    let id = TypeAliasDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderTypeAliasDecl(ctx, id, .empty)
  case BindingDecl.self:
    let id = BindingDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderBindingDecl(ctx, id, .empty)
  //case OperatorDecl.self
  case FunctionDecl.self:
    let id = FunctionDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderFunctionDecl(ctx, id, .empty)
  case MethodDecl.self:
    let id = MethodDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderMethodDecl(ctx, id, .empty)
  //case MethodImpl.self
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderSubscriptDecl(ctx, id, .empty)
  //case SubscriptImpl.self
  case InitializerDecl.self:
    let id = InitializerDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderInitializerDecl(ctx, id, .empty)
  case TraitDecl.self:
    let id = TraitDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderTraitDecl(ctx, id, .empty)
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(symbol)!
    return SimpleSymbolDeclRenderer.renderProductTypeDecl(ctx, id, .empty)
  default:
    return ""
  }
}
