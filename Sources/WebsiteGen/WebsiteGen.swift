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
public func generateDocumentation(db: DocumentationDatabase, typedProgram: TypedProgram, rootFolder: FolderAsset.ID, target: URL) {
    // TODO: instead of one rootFolder, we should have the list of modules which also contain their root folders.
    // We can pass a DocumentedProgram that contains DocumentationDatabase and a TypedProgram, as well as the modules to document.
    
    // Setup Context
    let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));
    let ctx = GenerationContext(
        documentation: db,
        stencil: stencil,
        typedProgram: typedProgram
    )
    
    //TODO Resolve URL's
    
    // Generate assets and symbols
    struct GeneratingVisitor: DocumentationVisitor {
        public func visitAsset(path: DynamicPath, assetId: AnyAssetID) {
            //TODO
        }
        
        public func visitSymbol(path: DynamicPath, symbolId: AnyDeclID) {
            //TODO
        }
    }
    let visitor = GeneratingVisitor()
    traverse(ctx: ctx, root: .folder(rootFolder), visitor: visitor)
    
    // Copy assets to target
}
