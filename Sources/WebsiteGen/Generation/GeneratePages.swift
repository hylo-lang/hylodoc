import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import Stencil

/// Context containing all the information needed to generate all the pages
public struct GenerationContext {
  let documentation: DocumentationContext
  var stencilEnvironment: Environment
  let htmlGenerator: some HyloReferenceResolvingGenerator = CustomHTMLGenerator()
  let exporter: Exporter

  var breadcrumb: [BreadcrumbItem]
  let tree: String
}

public func generateIndexAndTargetPages(
  documentation: DocumentationContext, exporter: Exporter
) throws {
  var stencil = createDefaultStencilEnvironment()
  var context = GenerationContext(
    documentation: documentation,
    stencilEnvironment: stencil,
    exporter: exporter,
    breadcrumb: [],
    tree: try generateTree(&stencil, documentation)
  )

  // Add name of the root to the breadcrumb stack
  context.breadcrumb.append(
    BreadcrumbItem(
      name: "Documentation",
      url: URL(fileURLWithPath: "/")
    ))

  // Generate all targets from the found roots
  try documentation.targetResolver.rootTargets.forEach {
    try generatePageForAnyTarget(&context, of: $0)
  }

  try generateModuleIndex(&context)
}

/// Generate the page belonging to this target
func generatePageForAnyTarget(_ context: inout GenerationContext, of targetId: AnyTargetID) throws {
  guard let resolvedTarget: ResolvedTarget = context.documentation.targetResolver[targetId]
  else {
    return
  }

  // Push breadcrumb item on stack
  context.breadcrumb.append(
    BreadcrumbItem(
      name: resolvedTarget.simpleName,
      url: resolvedTarget.url
    ))

  switch targetId {
  case .asset(let assetId):
    try generatePageForAnyAsset(&context, resolvedTarget, of: assetId)
    break
  case .decl(let declId):
    try generatePageForAnyDecl(&context, resolvedTarget, of: declId)
    break
  case .empty:
    break
  }

  // Generate children
  try resolvedTarget.children.forEach { try generatePageForAnyTarget(&context, of: $0) }

  // Pop breadcrumb item from stack
  let _ = context.breadcrumb.removeLast()
}

/// Generate the page belonging to this asset
func generatePageForAnyAsset(
  _ context: inout GenerationContext, _ resolvedTarget: ResolvedTarget, of assetId: AnyAssetID
)
  throws
{
  // Get context to render with
  let stencilContext =
    switch assetId {
    case .folder(let folderId):
      try prepareFolderPage(context, of: folderId)
    case .article(let articleId):
      try prepareArticlePage(context, of: articleId)
    case .sourceFile(let sourceFileId):
      try prepareSourceFilePage(context, of: sourceFileId)
    default:
      fatalError("unexpected asset")
    }

  // Render page and export content
  let content = try renderPage(&context, stencilContext, of: .asset(assetId))
  try context.exporter.exportHtml(content, at: resolvedTarget.url)
}

func generatePageForAnyDecl(
  _ context: inout GenerationContext, _ resolvedTarget: ResolvedTarget, of declId: AnyDeclID
)
  throws
{
  // Get context to render with
  let stencilContext =
    switch declId.kind {
    case AssociatedTypeDecl.self:
      try prepareAssociatedTypePage(context, of: AssociatedTypeDecl.ID(declId)!)
    case AssociatedValueDecl.self:
      try prepareAssociatedValuePage(context, of: AssociatedValueDecl.ID(declId)!)
    case TypeAliasDecl.self:
      try prepareTypeAliasPage(context, of: TypeAliasDecl.ID(declId)!)
    case BindingDecl.self:
      try prepareBindingPage(context, of: BindingDecl.ID(declId)!)
    case OperatorDecl.self:
      try prepareOperatorPage(context, of: OperatorDecl.ID(declId)!)
    case FunctionDecl.self:
      try prepareFunctionPage(context, of: FunctionDecl.ID(declId)!)
    case InitializerDecl.self:
      try prepareInitializerPage(context, of: InitializerDecl.ID(declId)!)
    case MethodDecl.self:
      try prepareMethodPage(context, of: MethodDecl.ID(declId)!)
    case SubscriptDecl.self:
      try prepareSubscriptPage(context, of: SubscriptDecl.ID(declId)!)
    case TraitDecl.self:
      try prepareTraitPage(context, of: TraitDecl.ID(declId)!)
    case ProductTypeDecl.self:
      try prepareProductTypePage(context, of: ProductTypeDecl.ID(declId)!)
    default:
      fatalError("unexpected decl")
    }

  // Render page and export content
  let content = try renderPage(&context, stencilContext, of: .decl(declId))
  try context.exporter.exportHtml(content, at: resolvedTarget.url)
}

public func generateModuleIndex(_ context: inout GenerationContext) throws {
  var env: [String: Any] = [:]
  env["pageType"] = "Home"

  // Article Content
  env["articleContent"] = "<p>Here is the list of documented modules:</p>"

  // Map children to an array of [(name, url)]
  env["contents"] = context.documentation.documentation.modules
    .map { context.documentation.targetResolver[.asset(.folder($0.rootFolder))]! }
    .map { ($0.simpleName, $0.url) }

  let content = try renderPage(
    &context,
    StencilContext(templateName: "folder_layout.html", context: env),
    of: .empty
  )
  try context.exporter.exportHtml(content, at: URL(fileURLWithPath: "/index.html"))
}

public func generateTree(_ stencil: inout Environment, _ documentation: DocumentationContext) throws
  -> String
{
  return try documentation.targetResolver.rootTargets.map {
    documentation.targetResolver.navigationItemFromTarget(targetId: $0)
  }
  .filter { $0 != nil }
  .map {
    try stencil.renderTemplate(name: "page_components/tree_item.html", context: ["item": $0 as Any])
  }
  .joined(separator: "\n")
}
