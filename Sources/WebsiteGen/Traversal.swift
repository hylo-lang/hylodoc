import Foundation
import FrontEnd
import DocumentationDB
import DequeModule

public protocol DocumentationVisitor {
    func visitAsset(path: DynamicPath, assetId: AnyAssetID)
    func visitSymbol(path: DynamicPath, symbolId: AnyDeclID)
}

/// Traverse all assets and symbols starting from a certain root node
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: asset to traverse
///   - visitor: documentation visitor to handle visits
public func traverse(ctx: GenerationContext, root: AnyAssetID, visitor: DocumentationVisitor) {
    var path = DynamicPath()
    traverseAssets(ctx: ctx, root: root, visitor: visitor, path: &path)
}

/// Traverse an asset and its children
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: asset to traverse
///   - visitor: documentation visitor to handle visits
///   - path: call-stack path
private func traverseAssets(ctx: GenerationContext, root: AnyAssetID, visitor: DocumentationVisitor, path: inout DynamicPath) {
    path.push(asset: root)
    
    // Visit
    visitor.visitAsset(path: path, assetId: root)
    
    switch root {
    case .folder(let id):
        // Traverse children
        let folder = ctx.documentation.assets.folders[id]!
        folder.children.forEach {
            child in traverseAssets(ctx: ctx, root: child, visitor: visitor, path: &path)
        }
        break
    case .sourceFile(let id):
        // Traverse children
        let sourceFile = ctx.documentation.assets.sourceFiles[documentationId: id]!
        ctx.typedProgram.ast[sourceFile.translationUnit]!.decls.forEach {
            child in traverseSymbols(ctx: ctx, root: child, visitor: visitor, path: &path)
        }
        break
    default:
        // rest of the asset types have no children
        break
    }
    
    path.pop()
}

/// Traverse all symbols in a source-file and visit them
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: source-file to traverse symbols off
///   - visitor: documentation visitor to handle visits
///   - path: call-stack path
private func traverseSymbols(ctx: GenerationContext, root: AnyDeclID, visitor: DocumentationVisitor, path: inout DynamicPath) {
    path.push(decl: root)
    
    // Visit
    visitor.visitSymbol(path: path, symbolId: root)
    
    switch root.kind {
    case AssociatedTypeDecl.self,
        AssociatedValueDecl.self,
        TypeAliasDecl.self,
        BindingDecl.self,
        OperatorDecl.self,
        FunctionDecl.self,
        MethodImpl.self,
        SubscriptImpl.self,
        InitializerDecl.self:
        // Supported, but they don't have children
        break
    case MethodDecl.self:
        let id = MethodDecl.ID(root)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Traverse children
        decl.impls.forEach {
            child in traverseSymbols(ctx: ctx, root: AnyDeclID(child), visitor: visitor, path: &path)
        }
        break
    case SubscriptDecl.self:
        let id = SubscriptDecl.ID(root)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Traverse children
        decl.impls.forEach {
            child in traverseSymbols(ctx: ctx, root: AnyDeclID(child), visitor: visitor, path: &path)
        }
        break
    case TraitDecl.self:
        let id = TraitDecl.ID(root)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Traverse children
        decl.members.forEach {
            child in traverseSymbols(ctx: ctx, root: child, visitor: visitor, path: &path)
        }
        break
    case ProductTypeDecl.self:
        let id = ProductTypeDecl.ID(root)!
        let decl = ctx.typedProgram.ast[id]!
        
        // Traverse children
        decl.members.forEach {
            child in traverseSymbols(ctx: ctx, root: child, visitor: visitor, path: &path)
        }
        break
    default:
        break
    }
    
    path.pop()
}
