import DocumentationDB
import Foundation
import MarkdownKit
import Stencil

/// Render the source-file page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: source file asset to render page of
///
/// - Returns: the contents of the rendered page
public func renderSourceFilePage(ctx: GenerationContext, of: SourceFileAsset) -> String {
  return ""
}

/// Render the article page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: article asset to render page of
///
/// - Returns: the contents of the rendered page
public func renderArticlePage(ctx: GenerationContext, of: ArticleAsset) throws -> String {
  var arr: [String: Any] = [:]

  if let title = of.title {
    arr["name"] = title
  } else {
    arr["name"] = of.name.components(separatedBy: ".").first!
  }

  arr["content"] = HtmlGenerator.standard.generate(block: of.content)

  return try ctx.stencil.renderTemplate(name: "article_layout.html", context: arr)
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
public func renderFolderPage(ctx: GenerationContext, of: FolderAsset) throws -> String {
  var arr: [String: Any] = [:]

  arr["name"] = of.name

  // check if folder has documentation
  if let overviewId = of.documentation {
    let overviewArticle = ctx.documentation.assets.articles[overviewId]!
    arr["overview"] = HtmlGenerator.standard.generate(block: overviewArticle.content)
  }

  let children = of.children.map { getAssetTitleAndUrl($0, ctx.documentation.assets) }
  if !children.isEmpty {
    arr["children"] = children
  }

  return try ctx.stencil.renderTemplate(name: "folder_layout.html", context: arr)
}

/// Get the title and the url of an asset
/// - Parameters:
///   - id: id of the asset
///   - assetsDB: database with assets
/// - Returns: Tuple containig String representing the title of the asset and url for the link to the asset's page
public func getAssetTitleAndUrl(_ id: AnyAssetID, _ assetsDB: AssetStore) -> (String, URL) {
  switch id {
  case .sourceFile(let sid):
    return (
      assetsDB.sourceFiles[sid]?.name ?? "SOURCE_FILE_NOT_FOUND",
      assetsDB.url(of: id) ?? URL(string: "/URL_NOT_FOUND")!
    )
  case .article(let aid):
    return (
      assetsDB.articles[aid]?.title ?? "ARTICLE_NOT_FOUND",
      assetsDB.url(of: id) ?? URL(string: "/URL_NOT_FOUND")!
    )
  case .folder(let fid):
    return (
      assetsDB.folders[fid]?.name ?? "FOLDER_NOT_FOUND",
      assetsDB.url(of: id) ?? URL(string: "/URL_NOT_FOUND")!
    )
  case .otherFile(let oid):
    return (
      assetsDB.otherFiles[oid]?.name ?? "OTHER_FILE_NOT_FOUND",
      assetsDB.url(of: id) ?? URL(string: "/URL_NOT_FOUND")!
    )
  }
}
/// Render the other-file page and return the result
///
/// Other files do not show up separatly, but are always embedded into other documentation such as that of symbols or other assets.
/// This method therefore returns the content directly from rendering the file.
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: other file asset to render page of
///
/// - Returns: the contents of the rendered local file
public func renderOtherFilePage(ctx: GenerationContext, of: OtherLocalFileAsset) -> String {
  return ""
}
