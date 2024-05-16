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
public func RenderAssetPage(ctx: GenerationContext, of: AnyAssetID) -> String {
    switch of {
    case .module(let id):
        let module = ctx.documentation.assetStore.modules[documentationId: id]!
        return RenderModulePage(ctx: ctx, of: module)
    case .sourceFile(let id):
        let sourceFile = ctx.documentation.assetStore.sourceFiles[documentationId: id]!
        return RenderSourceFilePage(ctx: ctx, of: sourceFile)
    case .article(let id):
        let article = ctx.documentation.assetStore.articles[id]!
        return RenderArticlePage(ctx: ctx, of: article)
    case .otherFile(let id):
        let otherFile = ctx.documentation.assetStore.otherFiles[id]!
        return RenderOtherFilePage(ctx: ctx, of: otherFile)
    default:
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
public func RenderSymbolPage(ctx: GenerationContext, of: AnyDeclID) -> String {
    switch of.kind {
    case AssociatedTypeDecl.self:
        let id = AssociatedTypeDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.associatedTypeDocs[astNodeId: id]!
        return RenderAssociatedTypePage(ctx: ctx, of: decl, with: declDoc)
    case AssociatedValueDecl.self:
        let id = AssociatedValueDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.associatedValueDocs[astNodeId: id]!
        return RenderAssociatedValuePage(ctx: ctx, of: decl, with: declDoc)
    case TypeAliasDecl.self:
        let id = TypeAliasDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.TypeAliasDocs[astNodeId: id]!
        return RenderTypeAliasPage(ctx: ctx, of: decl, with: declDoc)
    case BindingDecl.self:
        let id = BindingDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.BindingDocs[astNodeId: id]!
        return RenderBindingPage(ctx: ctx, of: decl, with: declDoc)
    case OperatorDecl.self:
        let id = OperatorDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.operatorDocs[astNodeId: id]!
        return RenderOperatorPage(ctx: ctx, of: decl, with: declDoc)
    case FunctionDecl.self:
        let id = FunctionDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.functionDocs[astNodeId: id]!
        return RenderFunctionPage(ctx: ctx, of: decl, with: declDoc)
    case MethodDecl.self:
        let id = MethodDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.methodDeclDocs[astNodeId: id]!
        return RenderMethodPage(ctx: ctx, of: decl, with: declDoc)
    case MethodImpl.self:
        let id = MethodImpl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.methodImplDocs[astNodeId: id]!
        return RenderMethodImplementationPage(ctx: ctx, of: decl, with: declDoc)
    case SubscriptDecl.self:
        let id = SubscriptDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.subscriptDeclDocs[astNodeId: id]!
        return RenderSubscriptPage(ctx: ctx, of: decl, with: declDoc)
    case SubscriptImpl.self:
        let id = SubscriptImpl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.subscriptImplDocs[astNodeId: id]!
        return RenderSubscriptImplementationPage(ctx: ctx, of: decl, with: declDoc)
    case InitializerDecl.self:
        let id = InitializerDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.initializerDocs[astNodeId: id]!
        return RenderInitializerPage(ctx: ctx, of: decl, with: declDoc)
    case TraitDecl.self:
        let id = TraitDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.traitDocs[astNodeId: id]!
        return RenderTraitPage(ctx: ctx, of: decl, with: declDoc)
    case ProductTypeDecl.self:
        let id = ProductTypeDecl.ID(cursor)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Render page
        let declDoc = ctx.documentation.symbols.productTypeDocs[astNodeId: id]!
        return RenderProductTypePage(ctx: ctx, of: decl, with: declDoc)
    default:
        return ""
    }
}
