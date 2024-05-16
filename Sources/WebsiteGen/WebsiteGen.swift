import Foundation
import FrontEnd
import DocumentationDB
import Stencil

public struct GenerationContext {
    public let documentation: DocumentationDatabase
    public let stencil: Environment
    public let typedProgram: TypedProgram
}

/// Render the full documentation website
///
/// - Parameters:
///   - db: documentation database
///   - ast: abstract syntax tree
///   - rootModule: the identity of the root module
public func GenerateDocumentation(db: DocumentationDatabase, typedProgram: TypedProgram, rootModule: ModuleAsset.ID, target: URL) {
    // Setup Context
    let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));
    let ctx = GenerationContext(
        documentation: db,
        stencil: stencil,
        typedProgram: typedProgram
    )
    
    // Resolve URL's
    //TraverseAssets(ctx: ctx, root: AnyAssetID(rootModule), visitor: nil)
    
    //TODO generate stuff
    
    // Copy assets to target
}
