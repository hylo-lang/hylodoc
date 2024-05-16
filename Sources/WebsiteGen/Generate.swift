import Foundation

/// Render and export an arbitrary asset page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: asset to render page of
///   - at: file location to export the content to
public func GenerateAsset(ctx: GenerationContext, of: AnyAssetID, at: URL) {
    // Create directory structure
    switch of {
    case .module(_):
    case .sourceFile(_):
        // Create directory
        //TODO Handle possible exception
        FileManager.default.createDirectory(atPath: at)
        
        // Extend path to write page to index.html in directory
        at.append(path: "index.html")
        break
    default:
        break
    }
    
    // Render page
    let content = RenderAssetPage(ctx: ctx, of: of)
    
    //TODO Handle possible exception
    content.write(to: at, atomically: true, encoding: String.Encoding.utf8)
}

/// Render and export an arbitrary symbol page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: symbol to render page of
///   - at: file location to export the content to
public func GenerateSymbol(ctx: GenerationContext, of: AnyDeclID, at: URL) {
    // Render page
    let content = RenderSymbolPage(ctx: ctx, of: of)
    
    //TODO Handle possible exception
    content.write(to: at, atomically: true, encoding: String.Encoding.utf8)
}
