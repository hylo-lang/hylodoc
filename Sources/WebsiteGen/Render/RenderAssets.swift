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
public func renderSourceFilePage(ctx: GenerationContext, of: SourceFileAsset) throws -> String {
    var arr: [String: Any] = [:]

    arr["name"] = of.name.components(separatedBy: ".").first!

    // check if file has summary
    if let summaryBlock = of.generalDescription.summary {
        arr["summary"] = HtmlGenerator.standard.generate(doc: summaryBlock)
    }
    // check if file has description
    if let descriptionBlock = of.generalDescription.description {
        arr["description"] = HtmlGenerator.standard.generate(doc: descriptionBlock)
    }

    let seeAlso = of.generalDescription.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    if !seeAlso.isEmpty {
        arr["seeAlso"] = seeAlso
    }

    return try ctx.stencil.renderTemplate(name: "sourceFile_layout.html", context: arr)
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

  var arr: [String: Any] = [:]

  if let title = article.title {
    arr["name"] = title
  } else {
    arr["name"] = article.name.components(separatedBy: ".").first!
  }

  arr["toRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.article(of)))
  arr["content"] = HtmlGenerator.standard.generate(doc: article.content)

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
public func renderFolderPage(ctx: GenerationContext, of: FolderAsset.ID) throws -> String {
  let folder = ctx.documentation.assets[of]!

  var arr: [String: Any] = [:]

  arr["name"] = folder.name
  arr["toRoot"] = ctx.urlResolver.pathToRoot(target: .asset(.folder(of)))

  // check if folder has documentation
  if let overviewId = folder.documentation {
    let overviewArticle = ctx.documentation.assets[overviewId]!
    arr["overview"] = HtmlGenerator.standard.generate(doc: overviewArticle.content)
  }

  let children = folder.children.map {
    childId in (getAssetTitle(childId, ctx.documentation.assets), ctx.urlResolver.refer(from: .asset(.folder(of)), to: .asset(childId)))
   }
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
public func renderOtherFilePage(ctx: GenerationContext, of: OtherLocalFileAsset.ID) throws -> String {
    return ""
}
