import Foundation
import DocumentationDB
import FrontEnd

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
    func file(from: URL, to: URL)
    func html(content: String, to: URL)
    func directory(to: URL)
}

/// Render and export an arbitrary asset page
///
/// - Precondition: assets should be breath or deapth first so all parent directories already exist
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: asset to render page of
///   - to: file location to export the content to
///   - with: exporter, used to handle file writes and directory creation
public func generateAsset(ctx: GenerationContext, of: AnyAssetID, to: inout URL, with: Exporter) {
    if case AnyAssetID.otherFile(let id) = of {
        // Copy file to target
        let otherFile = ctx.documentation.assetStore.otherFiles[id]!
        with.file(from: URL(fileURLWithPath: otherFile.fileName), to: to)
        return
    }
    
    // Create directory structure
    switch of {
    case .module(_),
        .sourceFile(_):
        // Create directory
        with.directory(to: to)
        
        // Extend path to write page to index.html in directory
        to.appendPathComponent("index.html")
        break
    default:
        break
    }
    
    // Render and export page
    let content = renderAssetPage(ctx: ctx, of: of)
    with.html(content: content, to: to)
}

/// Render and export an arbitrary symbol page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: symbol to render page of
///   - to: file location to export the content to
public func generateSymbol(ctx: GenerationContext, of: AnyDeclID, to: URL, with: Exporter) {
    // Render and export page
    let content = renderSymbolPage(ctx: ctx, of: of)
    with.html(content: content, to: to)
}
