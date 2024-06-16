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
public func renderSourceFilePage(ctx: inout GenerationContext, of: SourceFileAsset.ID) throws
  -> String
{
  let sourceFile: SourceFileAsset = ctx.documentation.assets[of]!
  let scope = ctx.typedProgram.nodeToScope[sourceFile.translationUnit]!
  let target = AnyTargetID.asset(AnyAssetID(of))
  let htmlGenerator = SimpleHTMLGenerator(
    context: .init(
      typedProgram: ctx.typedProgram, scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = sourceFile.name
  env["pageTitle"] = sourceFile.name
  env["pageType"] = "Source File"

  env["summary"] = sourceFile.generalDescription.summary.map(htmlGenerator.generate(document:))
  env["details"] = sourceFile.generalDescription.description.map(htmlGenerator.generate(document:))
  env["seeAlso"] = sourceFile.generalDescription.seeAlso.map(htmlGenerator.generate(document:))

  let translationUnit = ctx.typedProgram.ast[sourceFile.translationUnit]
  env["members"] = prepareMembersData(referringFrom: target, decls: translationUnit.decls, ctx: ctx)

  return try renderTemplate(ctx: &ctx, targetId: target, name: "source_file_layout.html", env: &env)
}

/// Render the article page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: article asset to render page of
///
/// - Returns: the contents of the rendered page
public func renderArticlePage(ctx: inout GenerationContext, of: ArticleAsset.ID) throws -> String {
  let article = ctx.documentation.assets[of]!
  let scope = AnyScopeID(article.moduleId)
  let target = AnyTargetID.asset(AnyAssetID(of))

  var env: [String: Any] = [:]

  if let title = article.title {
    env["name"] = title
  } else {
    env["name"] = article.name.components(separatedBy: ".").first ?? article.name
  }
  env["pageTitle"] = env["name"]
  env["pageType"] = "Article"

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.article(of)))
  env["content"] = ctx.htmlGenerator.generateResolvingHyloReferences(
    document: article.content,
    context: .init(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    )
  )

  return try renderTemplate(ctx: &ctx, targetId: target, name: "article_layout.html", env: &env)
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
public func renderFolderPage(ctx: inout GenerationContext, of: FolderAsset.ID) throws -> String {
  let folder = ctx.documentation.assets[of]!
  let scope = AnyScopeID(folder.moduleId)
  let target = AnyTargetID.asset(.folder(of))

  var env: [String: Any] = [:]

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)
  env["pageType"] = "Folder"

  // check if folder has documentation
  env["pageTitle"] = folder.name

  if let detailsId = folder.documentation {
    let detailsArticle = ctx.documentation.assets[detailsId]!

    env["articleContent"] = ctx.htmlGenerator.generateResolvingHyloReferences(
      document: detailsArticle.content,
      context: .init(
        typedProgram: ctx.typedProgram,
        scopeId: scope,
        resolveUrls: referWithSource(ctx.urlResolver, from: target)
      )
    )

    // todo refactor title handling to be at one place
    if let title = detailsArticle.title {
      env["pageTitle"] = title
    }
  }
  env["name"] = env["pageTitle"]

  env["contents"] = folder.children
    .filter { childId in
      let childAsset = ctx.documentation.assets[childId]!
      return !childAsset.isIndexPage && !(childAsset is OtherLocalFileAsset)
    }
    .map {
      childId in
      (
        getAssetTitle(childId, ctx.documentation.assets),
        ctx.urlResolver.refer(from: target, to: .asset(childId))
      )
    }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "folder_layout.html", env: &env)
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
