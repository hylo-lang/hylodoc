import Foundation
import FrontEnd
import DocumentationDB

protocol DocumentationVisitor {
    func VisitAsset(assetId: AnyAssetID)
    func VisitSymbol(sourceFile: SourceFileAsset, symbolId: AnyDeclID)
}

/// Traverse an asset and its children
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: asset to traverse
///   - visitor: documentation visitor to handle visits
public func TraverseAssets(ctx: GenerationContext, root: AnyAssetID, visitor: DocumentationVisitor) {
    switch root {
    case .module(let id):
        // Visit
        visitor.VisitAsset(assetId: root)
        
        // Traverse children
        let module = ctx.documentation.assetStore.modules[documentationId: id]!
        module.children.forEach(child -> TraverseAssets(ctx: ctx, root: child, visitor: visitor))
        break
    case .sourceFile(let id):
        // Visit
        visitor.VisitAsset(assetId: root)
        
        // Traverse children
        let sourceFile = ctx.documentation.assetStore.sourceFiles[documentationId: id]!
        TraverseSymbols(ctx: ctx, root: sourceFile, visitor: visitor)
        break
    default:
        visitor.VisitAsset(assetId: root)
        break
    }
}

/// Traverse all symbols in a source-file and visit them
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: source-file to traverse symbols off
///   - visitor: documentation visitor to handle visits
public func TraverseSymbols(ctx: GenerationContext, root: SourceFileAsset, visitor: DocumentationVisitor) {
    var stack: Deque<AnyDeclID> = Deque(ctx.typedProgram.ast[root.translationUnit]!.decls)
    while let cursor = stack.popLast() {
        switch cursor.kind {
        case AssociatedTypeDecl.self:
        case AssociatedValueDecl.self:
        case TypeAliasDecl.self:
        case BindingDecl.self:
        case OperatorDecl.self:
        case FunctionDecl.self:
        case MethodImpl.self:
        case SubscriptImpl.self:
        case InitializerDecl.self:
            visitor.VisitSymbol(sourceFile: root, symbolId: cursor)
            break
        case MethodDecl.self:
            let id = MethodDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            stack.append(contentsOf: decl.impls.map { child in return AnyDeclID(child) })
            
            // Visit
            visitor.VisitSymbol(sourceFile: root, symbolId: cursor)
            break
        case SubscriptDecl.self:
            let id = SubscriptDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            stack.append(contentsOf: decl.impls.map { child in return AnyDeclID(child) })
            
            // Visit
            visitor.VisitSymbol(sourceFile: root, symbolId: cursor)
            break
        case TraitDecl.self:
            let id = TraitDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            stack.append(contentsOf: decl.members)
            
            // Visit
            visitor.VisitSymbol(sourceFile: root, symbolId: cursor)
            break
        case ProductTypeDecl.self:
            let id = ProductTypeDecl.ID(cursor)!
            let decl = ctx.typedProgram.ast[id]!
            
            // Add children on top of stack
            stack.append(contentsOf: decl.members)
            
            // Visit
            visitor.VisitSymbol(sourceFile: root, symbolId: cursor)
            break
        default:
            break
        }
    }
}
