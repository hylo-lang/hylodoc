import DocumentationDB
import FrontEnd

public struct PartialResolvedTarget {
  let pathName: String
  let simpleName: String
  let navigationName: String
  let children: [AnyTargetID]
}

/// Partially resolve a target
func partialResolveTarget(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram,
  targetId: AnyTargetID
) -> PartialResolvedTarget {
  switch targetId {
  case .asset(let assetId):
    return partialResolveAsset(documentationDatabase, typedProgram, assetId: assetId)
  case .decl(let declId):
    return partialResolveDecl(documentationDatabase, typedProgram, declId: declId)
  case .empty:
    fatalError("unexpected empty target")
  }
}

/// Partially resolve an asset
func partialResolveAsset(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram, assetId: AnyAssetID
) -> PartialResolvedTarget {
  switch assetId {
  case .folder(let folderId):
    let folder: FolderAsset = documentationDatabase.assets[folderId]!

    // Display name of the folder
    var name: String = folder.name
    if let articleId = folder.documentation {
      if let article = documentationDatabase.assets[articleId], !article.isInternal {
        name = article.title ?? folder.name
      }
    }

    return PartialResolvedTarget(
      pathName: folder.name + "/index.html",
      simpleName: name,
      navigationName: name,
      children: folder.children
        .filter { folder.documentation == nil || $0 != .article(folder.documentation!) }
        .filter {
          // Filter out internal articles
          if case .article(let articleId) = $0,
            let article = documentationDatabase.assets[articleId]
          {
            return !article.isInternal
          }

          return true
        }
        .map { .asset($0) }
    )
  case .sourceFile(let sourceFileId):
    let sourceFile: SourceFileAsset = documentationDatabase.assets[sourceFileId]!

    return PartialResolvedTarget(
      pathName: String(sourceFile.name.components(separatedBy: ".").first ?? sourceFile.name)
        + "/index.html",
      simpleName: sourceFile.name,
      navigationName: sourceFile.name,
      children: typedProgram.ast[sourceFile.translationUnit]!.decls
        .filter(isSupportedDecl)
        .map { .decl($0) }
    )
  case .article(let articleId):
    let article: ArticleAsset = documentationDatabase.assets[articleId]!
    let name = article.title ?? (article.name.components(separatedBy: ".").first ?? article.name)

    return PartialResolvedTarget(
      pathName: (article.name.components(separatedBy: ".").first ?? article.name) + ".article.html",
      simpleName: name,
      navigationName: name,
      children: []
    )
  case .otherFile(let otherFileId):
    let otherFile: OtherLocalFileAsset = documentationDatabase.assets[otherFileId]!

    return PartialResolvedTarget(
      pathName: otherFile.name,
      simpleName: otherFile.name,
      navigationName: otherFile.name,
      children: []
    )
  }
}

/// Get the name of a declaration
func partialResolveDecl(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram, declId: AnyDeclID
) -> PartialResolvedTarget {
  switch declId.kind {
  case AssociatedTypeDecl.self:
    //let id = AssociatedTypeDecl.ID(declId)!
    let name = String(typedProgram.ast[declId]!.site.text)  //SimpleSymbolDeclRenderer.renderAssociatedTypeDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: name,  //NavigationSymbolDecRenderer.renderAssociatedTypeDecl(typedProgram, id),
      children: []
    )
  case AssociatedValueDecl.self:
    //let id = AssociatedValueDecl.ID(declId)!
    let name = String(typedProgram.ast[declId]!.site.text)  //SimpleSymbolDeclRenderer.renderAssociatedValueDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: name,  //NavigationSymbolDecRenderer.renderAssociatedValueDecl(typedProgram, id),
      children: []
    )
  case TypeAliasDecl.self:
    let id = TypeAliasDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderTypeAliasDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderTypeAliasDecl(typedProgram, id),
      children: []
    )
  case BindingDecl.self:
    let id = BindingDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderBindingDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderBindingDecl(typedProgram, id),
      children: []
    )
  case OperatorDecl.self:
    //let id = OperatorDecl.ID(declId)!
    let name = String(typedProgram.ast[declId]!.site.text)  //SimpleSymbolDeclRenderer.renderOperatorDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: name,  //NavigationSymbolDecRenderer.renderOperatorDecl(typedProgram, id),
      children: []
    )
  case FunctionDecl.self:
    let id = FunctionDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderFunctionDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderFunctionDecl(typedProgram, id),
      children: []
    )
  case MethodDecl.self:
    let id = MethodDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderMethodDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderMethodDecl(typedProgram, id),
      children: []
    )
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderSubscriptDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderSubscriptDecl(typedProgram, id),
      children: []
    )
  case InitializerDecl.self:
    let id = InitializerDecl.ID(declId)!
    let name = SimpleSymbolDeclRenderer.renderInitializerDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderInitializerDecl(typedProgram, id),
      children: []
    )
  case TraitDecl.self:
    let id = TraitDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderTraitDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderTraitDecl(typedProgram, id),
      children: decl.members.filter(isSupportedDecl).map { .decl($0) }
    )
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderProductTypeDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderProductTypeDecl(typedProgram, id),
      children: decl.members.filter(isSupportedDecl).map { .decl($0) }
    )
  default:
    fatalError("unexpected declaration" + String(describing: declId))
  }
}

public func isSupportedDecl(declId: AnyDeclID) -> Bool {
  switch declId.kind {
  case AssociatedTypeDecl.self,
    AssociatedValueDecl.self,
    TypeAliasDecl.self,
    BindingDecl.self,
    OperatorDecl.self,
    FunctionDecl.self,
    InitializerDecl.self,
    MethodDecl.self,
    SubscriptDecl.self,
    TraitDecl.self,
    ProductTypeDecl.self:
    return true
  default:
    return false
  }
}

/// Get all the targets that should refer back to the provided target
public func backReferencesOfTarget(_ typedProgram: TypedProgram, targetId: AnyTargetID)
  -> [AnyTargetID]?
{
  if case .decl(let declId) = targetId, let bindingId = BindingDecl.ID(declId) {
    let binding = typedProgram.ast[bindingId]!
    return resolvePatternToTargets(typedProgram, pattern: AnyPatternID(binding.pattern))
  }

  return nil
}

/// Recursively resolve patterns to target ID's
public func resolvePatternToTargets(_ typedProgram: TypedProgram, pattern: AnyPatternID)
  -> [AnyTargetID]
{
  // Binding pattern
  if let bindingPattern: BindingPattern = typedProgram.ast[BindingPattern.ID(pattern)] {
    return resolvePatternToTargets(typedProgram, pattern: bindingPattern.subpattern)
  }

  // Single variable pattern
  if let namePattern: NamePattern = typedProgram.ast[NamePattern.ID(pattern)] {
    return [.decl(AnyDeclID(namePattern.decl))]
  }

  // Tuple pattern
  if let tuplePattern: TuplePattern = typedProgram.ast[TuplePattern.ID(pattern)] {
    return tuplePattern.elements.flatMap {
      resolvePatternToTargets(typedProgram, pattern: $0.pattern)
    }
  }

  return []
}
