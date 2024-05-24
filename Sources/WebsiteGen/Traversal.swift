import DequeModule
import DocumentationDB
import Foundation
import FrontEnd

public protocol DocumentationVisitor {
  mutating func visit(path: TargetPath)
}

/// Traverse all assets and symbols starting from a certain root node
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: asset to traverse
///   - visitor: documentation visitor to handle visits
public func traverse(ctx: GenerationContext, root: AnyAssetID, visitor: inout DocumentationVisitor)
{
  var path = TargetPath(ctx: ctx)
  traverseAssets(ctx: ctx, root: root, visitor: &visitor, path: &path)
}

/// Traverse an asset and its children
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - root: asset to traverse
///   - visitor: documentation visitor to handle visits
///   - path: call-stack path
private func traverseAssets(
  ctx: GenerationContext, root: AnyAssetID, visitor: inout DocumentationVisitor,
  path: inout TargetPath
) {
  // Visit
  path.push(asset: root)
  visitor.visit(path: path)

  // Traverse
  switch root {
  case .folder(let id):
    // Traverse children
    let folder = ctx.documentation.assets.folders[id]!
    folder.children.forEach {
      child in traverseAssets(ctx: ctx, root: child, visitor: &visitor, path: &path)
    }
    break
  case .sourceFile(let id):
    // Traverse children
    let sourceFile = ctx.documentation.assets.sourceFiles[id]!
    ctx.typedProgram.ast[sourceFile.translationUnit]!.decls.forEach {
      child in traverseSymbols(ctx: ctx, root: child, visitor: &visitor, path: &path)
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
private func traverseSymbols(
  ctx: GenerationContext, root: AnyDeclID, visitor: inout DocumentationVisitor,
  path: inout TargetPath
) {
  // Visit
  path.push(decl: root)
  visitor.visit(path: path)

  // Traverse
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
      child in traverseSymbols(ctx: ctx, root: AnyDeclID(child), visitor: &visitor, path: &path)
    }
    break
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(root)!
    let decl = ctx.typedProgram.ast[id]!

    // Traverse children
    decl.impls.forEach {
      child in traverseSymbols(ctx: ctx, root: AnyDeclID(child), visitor: &visitor, path: &path)
    }
    break
  case TraitDecl.self:
    let id = TraitDecl.ID(root)!
    let decl = ctx.typedProgram.ast[id]!

    // Traverse children
    decl.members.forEach {
      child in traverseSymbols(ctx: ctx, root: child, visitor: &visitor, path: &path)
    }
    break
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(root)!
    let decl = ctx.typedProgram.ast[id]!

    // Traverse children
    decl.members.forEach {
      child in traverseSymbols(ctx: ctx, root: child, visitor: &visitor, path: &path)
    }
    break
  default:
    break
  }

  path.pop()
}
