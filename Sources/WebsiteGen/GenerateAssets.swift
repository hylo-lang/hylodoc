import DocumentationDB
import Foundation

/// Render the source-file page and export it at the right location
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: source file asset to render and export page of
///   - at: file location to export to
public func GenerateSourceFilePage(ctx: GenerationContext, of: SourceFileAsset, at: URL) {

}

/// Render the article page and export it at the right location
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: article asset to render and export page of
///   - at: file location to export to
public func GenerateArticlePage(ctx: GenerationContext, of: ArticleAsset, at: URL) {

}

/// Render the module page and export it at the right location
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: module asset to render and export page of
///   - at: file location to export to
public func GenerateModulePage(ctx: GenerationContext, of: ModuleAsset, at: URL) {

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
/// - Returns: the rendered content of the local file
public func GenerateOtherFilePage(ctx: GenerationContext, of: OtherLocalFileAsset) -> String {
    return ""
}
