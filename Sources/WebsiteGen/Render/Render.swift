import Foundation
import FrontEnd
import DocumentationDB

/// Render an arbitrary asset page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: asset to render page of
///
/// - Returns: the contents of the rendered page
public func renderAssetPage(ctx: GenerationContext, of: AnyAssetID) throws -> String {
    switch of {
    case .folder(let id):
        let folder = ctx.documentation.assets.folders[id]!
        return try renderFolderPage(ctx: ctx, of: folder)
    case .sourceFile(let id):
        let sourceFile = ctx.documentation.assets.sourceFiles[id]!
        return renderSourceFilePage(ctx: ctx, of: sourceFile)
    case .article(let id):
        let article = ctx.documentation.assets.articles[id]!
        return try renderArticlePage(ctx: ctx, of: article)
    case .otherFile(_):
        // Generic asset, like an image
        return ""
    }
}

/// Render an arbitrary symbol page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: symbol to render page of
///
/// - Returns: the contents of the rendered page
public func renderSymbolPage(ctx: GenerationContext, of: AnyDeclID) -> String {
    switch of.kind {
    case AssociatedTypeDecl.self:
        let id = AssociatedTypeDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.associatedTypeDocs[id]!
        return renderAssociatedTypePage(ctx: ctx, of: decl, with: declDoc)
    case AssociatedValueDecl.self:
        let id = AssociatedValueDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.associatedValueDocs[id]!
        return renderAssociatedValuePage(ctx: ctx, of: decl, with: declDoc)
    case TypeAliasDecl.self:
        let id = TypeAliasDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.TypeAliasDocs[id]!
        return renderTypeAliasPage(ctx: ctx, of: decl, with: declDoc)
    case BindingDecl.self:
        let id = BindingDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.BindingDocs[id]!
        return renderBindingPage(ctx: ctx, of: decl, with: declDoc)
    case OperatorDecl.self:
        let id = OperatorDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.operatorDocs[id]!
        return renderOperatorPage(ctx: ctx, of: decl, with: declDoc)
    case FunctionDecl.self:
        let id = FunctionDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.functionDocs[id]!
        return renderFunctionPage(ctx: ctx, of: decl, with: declDoc)
    case MethodDecl.self:
        let id = MethodDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.methodDeclDocs[id]!
        return renderMethodPage(ctx: ctx, of: decl, with: declDoc)
    case MethodImpl.self:
        let id = MethodImpl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.methodImplDocs[id]!
        return renderMethodImplementationPage(ctx: ctx, of: decl, with: declDoc)
    case SubscriptDecl.self:
        let id = SubscriptDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.subscriptDeclDocs[id]!
        return renderSubscriptPage(ctx: ctx, of: decl, with: declDoc)
    case SubscriptImpl.self:
        let id = SubscriptImpl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.subscriptImplDocs[id]!
        return renderSubscriptImplementationPage(ctx: ctx, of: decl, with: declDoc)
    case InitializerDecl.self:
        let id = InitializerDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.initializerDocs[id]!
        return renderInitializerPage(ctx: ctx, of: decl, with: declDoc)
    case TraitDecl.self:
        let id = TraitDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.traitDocs[id]!
        return renderTraitPage(ctx: ctx, of: decl, with: declDoc)
    case ProductTypeDecl.self:
        let id = ProductTypeDecl.ID(of)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.productTypeDocs[id]!
        return renderProductTypePage(ctx: ctx, of: decl, with: declDoc)
    default:
        return ""
    }
}
