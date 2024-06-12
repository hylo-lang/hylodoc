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
public func renderSourceFilePage(ctx: GenerationContext, of: SourceFileAsset.ID) throws -> String {
  let sourceFile: SourceFileAsset = ctx.documentation.assets[of]!

  var env: [String: Any] = [:]

  env["name"] = sourceFile.name
  env["pageTitle"] = sourceFile.name
  env["pageType"] = "Source File"

  // check if file has summary
  if let summaryBlock = sourceFile.generalDescription.summary {
    env["summary"] = ctx.htmlGenerator.generate(doc: summaryBlock)
  }

  // check if file has description
  if let descriptionBlock = sourceFile.generalDescription.description {
    env["details"] = ctx.htmlGenerator.generate(doc: descriptionBlock)
  }

  env["seeAlso"] = sourceFile.generalDescription.seeAlso.map {
    ctx.htmlGenerator.generate(doc: $0)
  }

  let translationUnit = ctx.typedProgram.ast[sourceFile.translationUnit]
  env["members"] = prepareMembersData(
    referringFrom: .asset(AnyAssetID(from: of)), decls: translationUnit.decls, ctx: ctx)

  return try renderTemplate(
    ctx: ctx, targetId: .asset(.sourceFile(of)), name: "source_file_layout.html", env: &env)
}

/// Render the article page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: article asset to render page of
///
/// - Returns: the contents of the rendered page
public func renderArticlePage(ctx: GenerationContext, of: ArticleAsset.ID) throws -> String {
  let article = ctx.documentation.assets[of]!

  var env: [String: Any] = [:]

  if let title = article.title {
    env["name"] = title
  } else {
    env["name"] = article.name.components(separatedBy: ".").first ?? article.name
  }
  env["pageTitle"] = env["name"]
  env["pageType"] = "Article"

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.article(of)))
  env["content"] = ctx.htmlGenerator.generate(doc: article.content)

  return try renderTemplate(
    ctx: ctx, targetId: .asset(.article(of)), name: "article_layout.html", env: &env)
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
public func renderFolderPage(ctx: GenerationContext, of: FolderAsset.ID) throws -> String {
  let folder = ctx.documentation.assets[of]!

  var env: [String: Any] = [:]

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.folder(of)))
  env["pageType"] = "Folder"

  // check if folder has documentation
  env["pageTitle"] = folder.name
  if let detailsId = folder.documentation {
    let detailsArticle = ctx.documentation.assets[detailsId]!
    env["articleContent"] = ctx.htmlGenerator.generate(doc: detailsArticle.content)
    if let title = detailsArticle.title {
      env["pageTitle"] = title
    }
  }
  env["name"] = env["pageTitle"]

  let children = folder.children
    .filter { childId in
      let childAsset = ctx.documentation.assets[childId]!
      return !childAsset.isIndexPage && !(childAsset is OtherLocalFileAsset)
    }
    .map {
      childId in
      (
        getAssetTitle(childId, ctx.documentation.assets),
        ctx.urlResolver.refer(from: .asset(.folder(of)), to: .asset(childId))
      )
    }
  if !children.isEmpty {
    env["contents"] = children
  }

  return try renderTemplate(
    ctx: ctx, targetId: .asset(.folder(of)), name: "folder_layout.html", env: &env)
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
