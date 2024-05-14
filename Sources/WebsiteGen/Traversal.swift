import Foundation
import FrontEnd
import DocumentationDB
import Stencil

/// Generate a module and its child assets
///
/// - Parameters:
///   - ctx: context used for page generation
///   - of: module to generate for
public func TraverseModule(ctx: GenerationContext, of: ModuleAsset) {
    // Generate module
    GenerateModulePage(ctx: ctx, of: of)
    
    // Generate module children
    TraverseModuleChildren(ctx: ctx, of: of.children)
}

/// Generate all child assets of a module
///
/// - Parameters:
///   - ctx: context used for page generation
///   - of: array of child asset ids
public func TraverseModuleChildren(ctx: GenerationContext, of: [AnyAssetID]) {
    for assetId in of {
        switch assetId {
        case .sourceFile(let id):
            let sourceFile = ctx.documentation.assetStore.sourceFiles[documentationId: id]!
            GenerateSourceFilePage(ctx: ctx, of: sourceFile)
            
            // Generate symbols in source-file
            TraverseSymbols(ctx: ctx, rootNode: sourceFile.translationUnit)
            break
        case .article(let id):
            let article = ctx.documentation.assetStore.articles[id]!
            GenerateArticlePage(ctx: ctx, of: article)
            break
        case .otherFile(_):
            // This can only be embedded and does not show up separatly
            break
        case .module(_):
            // This is already being taken care of in GenerateDocumentation
            break
        }
    }
}

/// Generate all child symbols of a root-node
///
/// - Parameters:
///   - ctx: context used for page generation
///   - rootNode: node to start traversing from
public func TraverseSymbols(_ ctx: GenerationContext, _ rootNode: TranslationUnit) {
    //TODO Traverse node -> node.decls
}
