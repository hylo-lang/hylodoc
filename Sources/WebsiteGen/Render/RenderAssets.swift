import DocumentationDB
import Foundation
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
public func renderArticlePage(ctx: GenerationContext, of: ArticleAsset) -> String {
    return ""
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
public func renderFolderPage(ctx: GenerationContext, of: FolderAsset) -> String {
    // get values
    let title = of.name
    let name = of.name
    let summary = getSummary(
        ctx.documentation.assetStore.articles[of.documentation!]!.content,
        ctx.documentation.markdownStore
        )
    let children = of.children.map { getAssetTitle($0, ctx.documentation.assetStore) }

    // create dictionary with structure [key: (value, block string)], for the renderPage function
    let arr: [String: (Any, String)] = [
        "title": (title, "{% block title %}{{ title }}{% endblock %}"),
        "name": (name, "{% block name %}{{ name }}{% endblock %}"),
        "summary": (summary, "{% block summary %}{{ summary }}{% endblock %}"),
        "topics": (children, "{% block topics %}{% for topic in topics %}<p>{{ topic }}</p>{% endfor %}{% endblock %}")
        ]

    return renderPage(ctx.stencil, arr)
}

/// Insert values to the template page and render it
/// - Parameters:
///   - stencil: Stencil Environment
///   - arr: [key: (value, block string)] dictionary with data for the temolate
/// - Returns: HTML String with inserted values or throws an error from renderTemplate
public func renderPage(_ stencil: Environment, _ arr: [String: (Any, String)]) -> String {
    var res = "{% extends \"index.html\" %}"
    // add blocks to the template
    for el in arr {
        res += el.value.1
    }

    // create dictionary with only values
    let arrOnlyValues = arr.mapValues{ $0.0}

    do {
        return try stencil.renderTemplate(string: res, context: arrOnlyValues)
    }
    catch {
        print("there was an error: \(error)")
        return arr.description
        // return res
    }
}

/// Get the title of an asset
/// - Parameters:
///   - id: id of the asset
///   - assetsDB: database with assets
/// - Returns: String representing the title of the asset
public func getAssetTitle(_ id: AnyAssetID, _ assetsDB: AssetStore) -> String {
    switch id {
    // case .sourceFile(let sid):
        // return assetsDB.sourceFiles[documentationId: sid]!.name // TODO: Fix this
    case .sourceFile(_) :
        return "Source File title placeholder"
    case .article(let aid):
        return assetsDB.articles[aid]!.title!
    case .module(let mid):
        return assetsDB.modules[documentationId: mid]!.name
    case .otherFile(_):
        return "Other File"
    }
}

/// Get the summary of a markdown node
/// - Parameters:
///   - id: id of the markdown node
///   - st: database with markdown nodes
/// - Returns: String representing the summary of the markdown node
public func getSummary(_ id: AnyMarkdownNodeID, _ st: MarkdownStore) -> String {
    switch id {
    case .ofText(let tid):
        return st.texts[tid]!.text
    default:
        return "Summary placeholder"
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
