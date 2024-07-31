import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit

struct SimpleSourceRange {
  typealias LineAndColumn = (line: Int, column: Int)
  public let start: LineAndColumn
  public let end: LineAndColumn

  public init(start: LineAndColumn, end: LineAndColumn) {
    self.start = start
    self.end = end
  }
}

extension SimpleSourceRange {
  public init(sourceRange: SourceRange) {
    self.init(
      start: sourceRange.start.lineAndColumn,
      end: sourceRange.end.lineAndColumn
    )
  }
}

func getOpenSourceUrl(
  repositoryRoot: URL, moduleSourceRoot: URL, sourceLocation: URL, site: SimpleSourceRange? = nil
) -> URL {

  let openSourceUrl =
    repositoryRoot
    .appendingPathComponents(sourceLocation.relativeInwardsPath(from: moduleSourceRoot)!)

  guard let site = site else { return openSourceUrl }

  return openSourceUrl.addingAnchor(
    anchor: "L\(site.start.line)C\(site.start.column)-L\(site.end.line)C\(site.end.column)")!
}

func openSourceUrlBuilder(repositoryRoot: URL, moduleSourceRoot: URL) -> (URL, SourceRange?) -> URL?
{
  return { (sourceLocation: URL, site: SourceRange?) in
    getOpenSourceUrl(
      repositoryRoot: repositoryRoot, moduleSourceRoot: moduleSourceRoot,
      sourceLocation: sourceLocation, site: site.map { SimpleSourceRange(sourceRange: $0) })
  }
}

func openSourceUrlBuilderForAssets(moduleSourceRoot: URL, moduleOpenSourceUrl: URL?) -> (URL) ->
  URL?
{
  if let repoUrl = moduleOpenSourceUrl {
    return { url in
      openSourceUrlBuilder(repositoryRoot: repoUrl, moduleSourceRoot: moduleSourceRoot)(url, nil)
    }
  }
  return { _ in nil }
}
func openSourceUrlBuilderForSymbols(moduleSourceRoot: URL, moduleOpenSourceUrl: URL?) -> (
  SourceRange
) -> URL? {
  if let repoUrl = moduleOpenSourceUrl {
    return { (site: SourceRange) in
      openSourceUrlBuilder(repositoryRoot: repoUrl, moduleSourceRoot: moduleSourceRoot)(
        site.file.url, site)
    }
  }
  return { _ in nil }
}

public struct PartialResolvedTarget {
  let pathName: String
  let simpleName: String
  let navigationName: String
  let metaDescription: String  // not escaped from " and & symbols
  let children: [AnyTargetID]
  let openSourceUrl: URL?
}

/// Partially resolve a target
func partialResolveTarget(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram, moduleRoot: URL,
  moduleOpenSourceUrl: URL?,
  targetId: AnyTargetID
) -> PartialResolvedTarget {
  switch targetId {
  case .asset(let assetId):
    return partialResolveAsset(
      documentationDatabase, typedProgram, moduleRoot: moduleRoot,
      moduleOpenSourceUrl: moduleOpenSourceUrl, assetId: assetId)
  case .decl(let declId):
    return partialResolveDecl(
      documentationDatabase, typedProgram, moduleRoot: moduleRoot,
      moduleOpenSourceUrl: moduleOpenSourceUrl, declId: declId)
  case .empty:
    fatalError("unexpected empty target")
  }
}

/// Partially resolve an asset
func partialResolveAsset(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram, moduleRoot: URL,
  moduleOpenSourceUrl: URL?, assetId: AnyAssetID
) -> PartialResolvedTarget {
  let openSourceUrlOf = openSourceUrlBuilderForAssets(
    moduleSourceRoot: moduleRoot, moduleOpenSourceUrl: moduleOpenSourceUrl)
  switch assetId {
  case .folder(let folderId):
    let folder: FolderAsset = documentationDatabase.assets[folderId]!

    var description = ""
    // Display name of the folder
    var name: String = folder.name
    if let articleId = folder.documentation {
      if let article = documentationDatabase.assets[articleId], !article.isInternal {
        name = article.title ?? folder.name
        description = metaDescriptionOf(document: article.content)
      }
    }
    if description.isEmpty {
      description = "Documentation of the folder \(folder.name)"
    }

    return PartialResolvedTarget(
      pathName: folder.name + "/index.html",
      simpleName: name,
      navigationName: name,
      metaDescription: description,
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
        .map { .asset($0) },
      openSourceUrl: openSourceUrlOf(folder.location)
    )
  case .sourceFile(let sourceFileId):
    let sourceFile: SourceFileAsset = documentationDatabase.assets[sourceFileId]!

    return PartialResolvedTarget(
      pathName: String(sourceFile.name.components(separatedBy: ".").first ?? sourceFile.name)
        + "/index.html",
      simpleName: sourceFile.name,
      navigationName: sourceFile.name,
      metaDescription: sourceFile.generalDescription.summary.map { metaDescriptionOf(document: $0) }
        ?? "Documentation of source file \(sourceFile.name))",
      children: typedProgram.ast[sourceFile.translationUnit]!.decls
        .filter(isSupportedDecl)
        .map { .decl($0) },
      openSourceUrl: openSourceUrlOf(sourceFile.location)
    )
  case .article(let articleId):
    let article: ArticleAsset = documentationDatabase.assets[articleId]!
    let name = article.title ?? (article.name.components(separatedBy: ".").first ?? article.name)

    return PartialResolvedTarget(
      pathName: (article.name.components(separatedBy: ".").first ?? article.name) + ".article.html",
      simpleName: name,
      navigationName: name,
      metaDescription: metaDescriptionOf(document: article.content),
      children: [],
      openSourceUrl: openSourceUrlOf(article.location)
    )
  case .otherFile(let otherFileId):
    let otherFile: OtherLocalFileAsset = documentationDatabase.assets[otherFileId]!

    return PartialResolvedTarget(
      pathName: otherFile.name,
      simpleName: otherFile.name,
      navigationName: otherFile.name,
      metaDescription: "",
      children: [],
      openSourceUrl: openSourceUrlOf(otherFile.location)
    )
  }
}

/// Get the name of a declaration
func partialResolveDecl(
  _ documentationDatabase: DocumentationDatabase, _ typedProgram: TypedProgram, moduleRoot: URL,
  moduleOpenSourceUrl: URL?, declId: AnyDeclID
) -> PartialResolvedTarget {
  let openSourceUrlOf = openSourceUrlBuilderForSymbols(
    moduleSourceRoot: moduleRoot, moduleOpenSourceUrl: moduleOpenSourceUrl)

  let symbols = documentationDatabase.symbols
  switch declId.kind {
  case AssociatedTypeDecl.self:
    let id = AssociatedTypeDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = String(decl.site.text)  //SimpleSymbolDeclRenderer.renderAssociatedTypeDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: name,  //NavigationSymbolDecRenderer.renderAssociatedTypeDecl(typedProgram, id),
      metaDescription: symbols.associatedTypeDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of associated type \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case AssociatedValueDecl.self:
    let id = AssociatedValueDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = String(decl.site.text)  //SimpleSymbolDeclRenderer.renderAssociatedValueDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: name,  //NavigationSymbolDecRenderer.renderAssociatedValueDecl(typedProgram, id),
      metaDescription: symbols.associatedValueDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of associated value \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case TypeAliasDecl.self:
    let id = TypeAliasDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderTypeAliasDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderTypeAliasDecl(typedProgram, id),
      metaDescription: symbols.typeAliasDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of type alias \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case BindingDecl.self:
    let id = BindingDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderBindingDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderBindingDecl(typedProgram, id),
      metaDescription: symbols.bindingDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of binding \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case OperatorDecl.self:
    let id = OperatorDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderOperatorDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderOperatorDecl(typedProgram, id),
      metaDescription: symbols.operatorDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of binding \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case FunctionDecl.self:
    let id = FunctionDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderFunctionDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderFunctionDecl(typedProgram, id),
      metaDescription: symbols.functionDocs[id]?.documentation.common.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of function \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case MethodDecl.self:
    let id = MethodDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderMethodDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderMethodDecl(typedProgram, id),
      metaDescription: symbols.methodDeclDocs[id]?.documentation.common.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of method \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderSubscriptDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderSubscriptDecl(typedProgram, id),
      metaDescription: symbols.subscriptDeclDocs[id]?.documentation.common.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of subscript \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case InitializerDecl.self:
    let id = InitializerDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderInitializerDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderInitializerDecl(typedProgram, id),
      metaDescription: symbols.initializerDocs[id]?.documentation.common.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of initializer \(name)",
      children: [],
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case TraitDecl.self:
    let id = TraitDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderTraitDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderTraitDecl(typedProgram, id),
      metaDescription: symbols.traitDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of trait \(name)",
      children: decl.members.filter(isSupportedDecl).map { .decl($0) },
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(declId)!
    let decl = typedProgram.ast[id]!
    let name = SimpleSymbolDeclRenderer.renderProductTypeDecl(typedProgram, id)

    return PartialResolvedTarget(
      pathName: name.components(separatedBy: " ").last! + "/index.html",
      simpleName: name,
      navigationName: NavigationSymbolDecRenderer.renderProductTypeDecl(typedProgram, id),
      metaDescription: symbols.productTypeDocs[id]?.common.summary.map {
        metaDescriptionOf(document: $0)
      } ?? "Documentation of product type \(name)",
      children: decl.members.filter(isSupportedDecl).map { .decl($0) },
      openSourceUrl: openSourceUrlOf(decl.site)
    )
  default:
    fatalError("unexpected declaration: " + declId.description)
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
public func backReferencesOfTarget(
  targetId: AnyTargetID, typedProgram: TypedProgram, documentationDatabase: DocumentationDatabase
)
  -> [AnyTargetID]
{
  if case .decl(let declId) = targetId, let bindingId = BindingDecl.ID(declId) {
    let binding = typedProgram.ast[bindingId]!
    return resolvePatternToTargets(typedProgram, pattern: AnyPatternID(binding.pattern))
  }
  if case .asset(let assetId) = targetId, case .folder(let folderAssetId) = assetId {
    let associatedArticle = documentationDatabase.assets[folderAssetId]?.documentation
    if let articleId = associatedArticle {
      return [.asset(.article(articleId))]
    }
  }

  return []
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

func escapeStringForHTMLAttribute(_ input: String) -> String {
  return input.replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "\"", with: "&quot;")
}

func metaDescriptionOf(document: Block) -> String {
  guard case .document(let blocks) = document else {
    preconditionFailure("expected a document block, got \(document)")
  }

  for block in blocks {
    if case .paragraph(let content) = block {
      return content.rawDescription.prefix(155).description
    }
  }
  return ""
}
