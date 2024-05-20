import DocumentationDB
import Foundation

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
    return ""
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
