import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import Stencil

/// Render the source-file page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: source file asset to render page of
///
/// - Returns: the contents of the rendered page
public func prepareSourceFilePage(_ context: GenerationContext, of: SourceFileAsset.ID)
  -> StencilContext
{
  let sourceFile: SourceFileAsset = context.documentation.documentation.assets[of]!
  let scope = ctx.typedProgram.nodeToScope[sourceFile.translationUnit]!
  let target = AnyTargetID.asset(AnyAssetID(of))
  let htmlGenerator = SimpleHTMLGenerator(
    context: .init(
      typedProgram: context.resolved.typedProgram, scopeId: scope,
      resolveUrls: referWithSource(context.resolved.targetResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]
  env["pageType"] = "Source File"

  env["summary"] = sourceFile.generalDescription.summary.map(htmlGenerator.generate(document:))
  env["details"] = sourceFile.generalDescription.description.map(htmlGenerator.generate(document:))
  env["seeAlso"] = sourceFile.generalDescription.seeAlso.map(htmlGenerator.generate(document:))

  let translationUnit = ctx.typedProgram.ast[sourceFile.translationUnit]
  env["members"] = prepareMembersData(context, referringFrom: target, decls: translationUnit.decls)

  return StencilContext(templateName: "source_file_layout.html", context: env)
}

/// Render the article page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: article asset to render page of
///
/// - Returns: the contents of the rendered page
public func prepareArticlePage(_ context: GenerationContext, of: ArticleAsset.ID) -> StencilContext
{
  let article = context.documentation.documentation.assets[of]!
  let scope = AnyScopeID(article.moduleId)
  let target = AnyTargetID.asset(AnyAssetID(of))

  var env: [String: Any] = [:]
  env["pageType"] = "Article"
  env["content"] = context.htmlGenerator.generate(doc: article.content)

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.article(of)))
  env["content"] = ctx.htmlGenerator.generateResolvingHyloReferences(
    document: article.content,
    context: .init(
      typedProgram: context.resolved.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(context.resolved.targetResolver, from: target)
    )
  )

  return StencilContext(templateName: "article_layout.html", context: env)
}

extension Asset {
  var isIndexPage: Bool {
    return location.isFileURL && isIndexPageFileName(fileName: location.lastPathComponent)
  }
}
func isIndexPageFileName(fileName: String) -> Bool {
  return fileName == "index.hylodoc" || fileName == "index.internal.hylodoc"
}

/// Renders the page for a folder
///
/// Displays the folder title as a title, optionally the content of the related article (FolderAsset.documentation),
/// and a list of child assets along with links and their summaries.
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: module asset to render page of
///
/// - Returns: the contents of the rendered page
public func prepareFolderPage(_ context: GenerationContext, of: FolderAsset.ID) -> StencilContext {
  let folder = context.documentation.documentation.assets[of]!
  let scope = AnyScopeID(folder.moduleId)
  let target = AnyTargetID.asset(.folder(of))

  var env: [String: Any] = [:]
  env["pageType"] = "Folder"

  // check if folder has documentation
  if let detailsId = folder.documentation {
    let detailsArticle = context.documentation.documentation.assets[detailsId]!

    env["articleContent"] = context.htmlGenerator.generateResolvingHyloReferences(
      document: detailsArticle.content,
      context: .init(
        typedProgram: ctx.typedProgram,
        scopeId: scope,
        resolveUrls: referWithSource(ctx.urlResolver, from: target)
      )
    )

    // todo refactor title handling to be at one place
    //    if let title = detailsArticle.title {
    //      env["pageTitle"] = title
    //    }
  }

  // Map children to an array of [(name, relativePath)]
  env["contents"] = context.documentation.targetResolver[.asset(.folder(of))]!.children
    .map { context.documentation.targetResolver[$0]! }
    .map { ($0.simpleName, $0.relativePath) }

  return StencilContext(templateName: "folder_layout.html", context: env)
}

/// Get the title and the url of an asset
/// - Parameters:
///   - id: id of the asset
///   - assetsDB: database with assets
/// - Returns: Tuple containig String representing the title of the asset and url for the link to the asset's page
public func getAssetTitle(_ id: AnyAssetID, _ assetsDB: AssetStore) -> String {
  switch id {
  case .sourceFile(let sid):
    return assetsDB.sourceFiles[sid]!.name
  case .article(let aid):
    let article = assetsDB.articles[aid]!
    return article.title ?? String(article.name.lazy.split(separator: ".")[0])
  case .folder(let fid):
    return assetsDB.folders[fid]!.name
  case .otherFile(let oid):
    return assetsDB.otherFiles[oid]!.name
  }
}
