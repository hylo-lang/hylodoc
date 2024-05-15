import Foundation
import FrontEnd
import DocumentationDB
import Stencil
import DequeModule

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
public func TraverseSymbols(ctx: GenerationContext, rootNode: TranslationUnit.ID) {
    var stack: Deque<AnyDeclID> = Deque(ctx.typedProgram.ast[rootNode].decls)
    while let cursor = stack.popLast() {
        switch cursor.kind {
        case AssociatedTypeDecl.self:
            let id = AssociatedTypeDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.associatedTypeDocs[astNodeId: id]!
            GenerateAssociatedTypePage(ctx: ctx, of: decl, with: declDoc)
            break
        case AssociatedValueDecl.self:
            let id = AssociatedValueDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.associatedValueDocs[astNodeId: id]!
            GenerateAssociatedValuePage(ctx: ctx, of: decl, with: declDoc)
            break
        case TypeAliasDecl.self:
            let id = TypeAliasDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.TypeAliasDocs[astNodeId: id]!
            GenerateTypeAliasPage(ctx: ctx, of: decl, with: declDoc)
            break
        case BindingDecl.self:
            let id = BindingDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.BindingDocs[astNodeId: id]!
            GenerateBindingPage(ctx: ctx, of: decl, with: declDoc)
            break
        case OperatorDecl.self:
            let id = OperatorDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.operatorDocs[astNodeId: id]!
            GenerateOperatorPage(ctx: ctx, of: decl, with: declDoc)
            break
        case FunctionDecl.self:
            let id = FunctionDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.functionDocs[astNodeId: id]!
            GenerateFunctionPage(ctx: ctx, of: decl, with: declDoc)
            break
        case MethodDecl.self:
            let id = MethodDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            for child in decl.impls {
                stack.append(AnyDeclID(child))
            }
            
            // Generate page
            let declDoc = ctx.documentation.symbols.methodDeclDocs[astNodeId: id]!
            GenerateMethodPage(ctx: ctx, of: decl, with: declDoc)
            break
        case MethodImpl.self:
            let id = MethodImpl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.methodImplDocs[astNodeId: id]!
            GenerateMethodImplementationPage(ctx: ctx, of: decl, with: declDoc)
            break
        case SubscriptDecl.self:
            let id = SubscriptDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            for child in decl.impls {
                stack.append(AnyDeclID(child))
            }
            
            // Generate page
            let declDoc = ctx.documentation.symbols.subscriptDeclDocs[astNodeId: id]!
            GenerateSubscriptPage(ctx: ctx, of: decl, with: declDoc)
            break
        case SubscriptImpl.self:
            let id = SubscriptImpl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.subscriptImplDocs[astNodeId: id]!
            GenerateSubscriptImplementationPage(ctx: ctx, of: decl, with: declDoc)
            break
        case InitializerDecl.self:
            let id = InitializerDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Generate page
            let declDoc = ctx.documentation.symbols.initializerDocs[astNodeId: id]!
            GenerateInitializerPage(ctx: ctx, of: decl, with: declDoc)
            break
        case TraitDecl.self:
            let id = TraitDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            for child in decl.members {
                stack.append(child)
            }
            
            // Generate page
            let declDoc = ctx.documentation.symbols.traitDocs[astNodeId: id]!
            GenerateTraitPage(ctx: ctx, of: decl, with: declDoc)
            break
        case ProductTypeDecl.self:
            let id = ProductTypeDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            for child in decl.members {
                stack.append(child)
            }
            
            // Generate page
            let declDoc = ctx.documentation.symbols.productTypeDocs[astNodeId: id]!
            GenerateProductTypePage(ctx: ctx, of: decl, with: declDoc)
            break
        default:
            break
        }
    }
}
