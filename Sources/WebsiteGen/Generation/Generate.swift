import DequeModule
import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import Stencil

public struct RenderContext {
  let resolved: ResolvedDocumentation
  var stencilEnvironment: Environment
  let htmlGenerator: some HyloReferenceResolvingGenerator
  let exportPath: AbsolutePath
  let exporter: Exporter

  var breadcrumb: Deque<BreadcrumbItem>
}

public func generate(
  resolved: ResolvedDocumentation, exportPath: AbsolutePath, exporter: Exporter
) throws {
  var context = RenderContext(
    resolved: resolved,
    stencilEnvironment: createDefaultStencilEnvironment(),
    htmlGenerator: CustomHTMLGenerator(),
    exportPath: exportPath,
    exporter: exporter,
    breadcrumb: []
  )

  // Figure out the name of the documentation root
  let rootName: String
  if resolved.documentation.modules.count > 1 {
    rootName = "Documentation"
  } else {
    let module: ModuleInfo = resolved.documentation.modules.first { $0 }!
    rootName = module.name
  }

  // Add rootName to the breadcrumb stack
  context.breadcrumb.append(
    BreadcrumbItem(name: rootName, relativePath: RelativePath(pathString: ".")))

  // Generate all targets from the found roots
  try resolved.targetResolver.rootTargets.forEach {
    try generateTarget(&context, targetId: $0)
  }

  if resolved.documentation.modules.count > 1 {
    // TODO generate a module index page
  } else {
    // TODO folder documentation of the only module is the index page
  }
}

/// Generate the page belonging to this target
func generateTarget(_ context: inout RenderContext, targetId: AnyTargetID) throws {
  guard let resolvedTarget: ResolvedTarget = context.resolved.targetResolver[targetId]
  else {
    return
  }

  // Push breadcrumb item on stack
  context.breadcrumb.append(
    BreadcrumbItem(
      name: resolvedTarget.simpleName,
      relativePath: resolvedTarget.relativePath
    ))

  switch targetId {
  case .asset(let assetId):
    try generateAsset(&context, resolvedTarget, assetId: assetId)
    break
  case .decl(let declId):
    try generateDecl(&context, resolvedTarget, declId: declId)
    break
  case .empty:
    break
  }

  // Generate children
  try resolvedTarget.children.forEach { try generateTarget(&context, targetId: $0) }

  // Pop breadcrumb item from stack
  let _ = context.breadcrumb.popLast()
}

/// Generate the page belonging to this asset
func generateAsset(
  _ context: inout RenderContext, _ resolvedTarget: ResolvedTarget, assetId: AnyAssetID
)
  throws
{
  let exportPath = URL(path: resolvedTarget.relativePath.absolute(in: context.exportPath))

  // Copy other file to the right path
  if case .otherFile(let otherFileId) = assetId {
    let otherFile = context.resolved.documentation.assets[otherFileId]!
    try context.exporter.file(
      from: otherFile.location,
      to: exportPath
    )
    return
  }

  // Get context to render with
  let stencilContext =
    switch assetId {
    case .folder(let folderId):
      renderFolderPage(context, of: folderId)
    case .article(let articleId):
      renderArticlePage(context, of: articleId)
    case .sourceFile(let sourceFileId):
      renderSourceFilePage(context, of: sourceFileId)
    default:
      fatalError("unexpected asset")
    }

  // Render page and export content
  let content = try renderPage(&context, stencilContext, targetId: .asset(assetId))
  try context.exporter.html(content: content, to: exportPath)
}

func generateDecl(
  _ context: inout RenderContext, _ resolvedTarget: ResolvedTarget, declId: AnyDeclID
)
  throws
{
  let exportPath = URL(path: resolvedTarget.relativePath.absolute(in: context.exportPath))

  // Get context to render with
  let stencilContext =
    switch declId.kind {
    case AssociatedTypeDecl.self:
      renderAssociatedTypePage(context, of: AssociatedTypeDecl.ID(declId))
    case AssociatedValueDecl.self:
      renderAssociatedValuePage(context, of: AssociatedValueDecl.ID(declId))
    case TypeAliasDecl.self:
      renderTypeAliasPage(context, of: TypeAliasDecl.ID(declId))
    case BindingDecl.self:
      renderBindingPage(context, of: BindingDecl.ID(declId))
    case OperatorDecl.self:
      renderOperatorPage(context, of: OperatorDecl.ID(declId))
    case FunctionDecl.self:
      renderFunctionPage(context, of: FunctionDecl.ID(declId))
    case InitializerDecl.self:
      renderInitializerPage(context, of: InitializerDecl.ID(declId))
    case MethodDecl.self:
      renderMethodPage(context, of: MethodDecl.ID(declId))
    case SubscriptDecl.self:
      renderSubscriptPage(context, of: SubscriptDecl.ID(declId))
    case TraitDecl.self:
      renderTraitPage(context, of: TraitDecl.ID(declId))
    case ProductTypeDecl.self:
      renderProductTypePage(context, of: ProductTypeDecl.ID(declId))
    default:
      fatalError("unexpected decl")
    }

  // Render page and export content
  let content = try renderPage(&context, stencilContext, targetId: .decl(declId))
  try context.exporter.html(content: content, to: exportPath)
}

//public func generateModuleIndexDocumentation(
//  ctx: inout GenerationContext, exporter: Exporter, target: URL
//) {
//  var env: [String: Any] = [:]
//
//  env["pathToRoot"] = "."
//  env["pageType"] = "Folder"
//
//  // check if folder has documentation
//  env["pageTitle"] = "Documentation"
//  env["name"] = env["pageTitle"]
//
//  env["contents"] = ctx.documentation.modules.map {
//    module in
//    (
//      getAssetTitle(.folder(module.rootFolder), ctx.documentation.assets),
//      ctx.targetResolver.refer(from: .empty, to: .asset(.folder(module.rootFolder)))
//    )
//  }
//
//  let content = try! renderTemplate(
//    ctx: &ctx, targetId: .empty, name: "folder_layout.html", env: &env)
//  try! exporter.html(content: content, to: URL(fileURLWithPath: "index.html", relativeTo: target))
//}
