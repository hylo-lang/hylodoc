import DocumentationDB
import Foundation
import FrontEnd
import Stencil

/// Extension to the Stencil Environment struct to allow for default behavior of whitespace control and custom filters
/// Removes whitespace before a block and whitespace and a single newline after a block (from https://github.com/stencilproject/Stencil/blob/master/Sources/Stencil/TrimBehaviour.swift)
extension Environment {
  public init(loader: Loader?) {
    let ext = Extension()
    ext.registerFilter("lowercaseAndHyphen") {(value: Any?) in lowercaseAndHyphenFilter(value)}

    self.init(
      loader: loader,
      extensions: [ext],
      trimBehaviour: .smart
      )
  }
}

/// Convert a string to lowercase words separated by hyphens
/// - Parameter value: the string to convert
/// - Returns: the converted string, or the original value if it is not a string
func lowercaseAndHyphenFilter(_ value: Any?) -> Any? {
    guard let string = value as? String else { return value }
    
    // Lowercase each word
    let lowercasedWords = string.split(separator: " ").map { $0.lowercased() }
    
    // Join with hyphen
    return lowercasedWords.joined(separator: "-")
}

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
    return try renderFolderPage(ctx: ctx, of: id)
  case .sourceFile(let id):
    return try renderSourceFilePage(ctx: ctx, of: id)
  case .article(let id):
    return try renderArticlePage(ctx: ctx, of: id)
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
public func renderSymbolPage(ctx: GenerationContext, of: AnyDeclID) throws -> String {
  switch of.kind {
  case AssociatedTypeDecl.self:
    let id = AssociatedTypeDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.associatedTypeDocs[id]
    return try renderAssociatedTypePage(ctx: ctx, of: id, with: declDoc)
  case AssociatedValueDecl.self:
    let id = AssociatedValueDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.associatedValueDocs[id]
    return try renderAssociatedValuePage(ctx: ctx, of: id, with: declDoc)
  case TypeAliasDecl.self:
    let id = TypeAliasDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.typeAliasDocs[id]
    return try renderTypeAliasPage(ctx: ctx, of: id, with: declDoc)
  case BindingDecl.self:
    let id = BindingDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.bindingDocs[id]
    return try renderBindingPage(ctx: ctx, of: id, with: declDoc)
  case OperatorDecl.self:
    let id = OperatorDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.operatorDocs[id]
    return try renderOperatorPage(ctx: ctx, of: id, with: declDoc)
  case FunctionDecl.self:
    let id = FunctionDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.functionDocs[id]
    return try renderFunctionPage(ctx: ctx, of: id, with: declDoc)
  case MethodDecl.self:
    let id = MethodDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.methodDeclDocs[id]
    return try renderMethodPage(ctx: ctx, of: id, with: declDoc)
  case MethodImpl.self:
    let id = MethodImpl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.methodImplDocs[id]
    return try renderMethodImplementationPage(ctx: ctx, of: id, with: declDoc)
  case SubscriptDecl.self:
    let id = SubscriptDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.subscriptDeclDocs[id]
    return try renderSubscriptPage(ctx: ctx, of: id, with: declDoc)
  case SubscriptImpl.self:
    let id = SubscriptImpl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.subscriptImplDocs[id]
    return try renderSubscriptImplementationPage(ctx: ctx, of: id, with: declDoc)
  case InitializerDecl.self:
    let id = InitializerDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.initializerDocs[id]
    return try renderInitializerPage(ctx: ctx, of: id, with: declDoc)
  case TraitDecl.self:
    let id = TraitDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.traitDocs[id]
    return try renderTraitPage(ctx: ctx, of: id, with: declDoc)
  case ProductTypeDecl.self:
    let id = ProductTypeDecl.ID(of)!

    // Render page
    let declDoc = ctx.documentation.symbols.productTypeDocs[id]
    return try renderProductTypePage(ctx: ctx, of: id, with: declDoc)
  default:
    return ""
  }
}
