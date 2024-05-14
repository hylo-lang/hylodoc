import Foundation
import FrontEnd
import DocumentationDB
import Stencil

public struct GenerationContext {
    public let documentation: DocumentationDatabase
    public let stencil: Environment
    public let typedProgram: TypedProgram
}

/// Generate the full documentation website
///
/// - Parameters:
///   - db: documentation database
///   - ast: abstract syntax tree
public func GenerateDocumentation(db: DocumentationDatabase, typedProgram: TypedProgram, rootModule: ModuleDecl.ID) {
    // Setup Context
    let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));
    let ctx = GenerationContext(documentation: db, stencil: stencil, typedProgram: typedProgram)
    
    // Traverse modules from root in breath-first order and generate pages
    let moduleIds = db.assetStore.modules.allDescendantModules(ofAstNodeId: rootModule)
    for moduleId in moduleIds {
        let module = db.assetStore.modules[documentationId: moduleId]!
        TraverseModule(ctx: ctx, of: module)
    }
    
    // Copy assets to target
}
