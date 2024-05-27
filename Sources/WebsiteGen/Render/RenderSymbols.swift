import FrontEnd
import DocumentationDB
import Foundation
import MarkdownKit

/// Render the associated-type page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-type declaration to render page of
///   - with: parsed associated-type documentation string
///
/// - Returns: contents of the rendered page
public func renderAssociatedTypePage(ctx: GenerationContext, of: AssociatedTypeDecl.ID, with: AssociatedTypeDocumentation) throws -> String {
    return ""
}

/// Render the associated-value page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-value declaration to render page of
///   - with: parsed associated-value documentation string
///
/// - Returns: contents of the rendered page
public func renderAssociatedValuePage(ctx: GenerationContext, of: AssociatedValueDecl.ID, with: AssociatedValueDocumentation) throws -> String {
    return ""
}

/// Render the type-alias page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: type-alias declaration to render page of
///   - with: parsed type-alias documentation string
///
/// - Returns: contents of the rendered page
public func renderTypeAliasPage(ctx: GenerationContext, of: TypeAliasDecl.ID, with: TypeAliasDocumentation) throws -> String {
    let decl: TypeAliasDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]
    args["name"] = decl.identifier.value
    args["code"] = decl.site.text
    args["toRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    // Summary
    if let summary = with.common.summary {
        args["summary"] = HtmlGenerator.standard.generate(doc: summary)
    }

    // Overview
    if let block = with.common.description {
        args["overview"] = HtmlGenerator.standard.generate(doc: block)
    }

    return try ctx.stencil.renderTemplate(name: "symbol_layout.html", context: args)
}

/// Render the binding page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: binding declaration to render page of
///   - with: parsed binding documentation string
///
/// - Returns: contents of the rendered page
public func renderBindingPage(ctx: GenerationContext, of: BindingDecl.ID, with: BindingDocumentation) throws -> String {
    return ""
}

/// Render the operator page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: operator declaration to render page of
///   - with: parsed operator documentation string
///
/// - Returns: contents of the rendered page
public func renderOperatorPage(ctx: GenerationContext, of: OperatorDecl.ID, with: OperatorDocumentation) throws -> String {
    return ""
}

/// Render the function page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: function declaration to render page of
///   - with: parsed function documentation string
///
/// - Returns: contents of the rendered page
public func renderFunctionPage(ctx: GenerationContext, of: FunctionDecl.ID, with: FunctionDocumentation) throws -> String {
    return ""
}

/// Render the method page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: method declaration to render page of
///   - with: parsed method documentation string
///
/// - Returns: contents of the rendered page
public func renderMethodPage(ctx: GenerationContext, of: MethodDecl.ID, with: MethodDeclDocumentation) throws -> String {
    return ""
}

/// Render the method-implementation page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: method-implementation declaration to render page of
///   - with: parsed method-implementation documentation string
///
/// - Returns: contents of the rendered page
public func renderMethodImplementationPage(ctx: GenerationContext, of: MethodImpl.ID, with: MethodImplDocumentation) throws -> String {
    return ""
}

/// Render the subscript page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: subscript declaration to render page of
///   - with: parsed subscript documentation string
///
/// - Returns: contents of the rendered page
public func renderSubscriptPage(ctx: GenerationContext, of: SubscriptDecl.ID, with: SubscriptDeclDocumentation) throws -> String {
    return ""
}

/// Render the subscript-implementation page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: subscript-implementation declaration to render page of
///   - with: parsed subscript-implementation documentation string
///
/// - Returns: contents of the rendered page
public func renderSubscriptImplementationPage(ctx: GenerationContext, of: SubscriptImpl.ID, with: SubscriptImplDocumentation) throws -> String {
    return ""
}

/// Render the initializer page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: initializer declaration to render page of
///   - with: parsed initializer documentation string
///
/// - Returns: contents of the rendered page
public func renderInitializerPage(ctx: GenerationContext, of: InitializerDecl.ID, with: InitializerDocumentation) throws -> String {
    return ""
}

/// Render the trait page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: trait declaration to render page of
///   - with: parsed trait documentation string
///
/// - Returns: contents of the rendered page
public func renderTraitPage(ctx: GenerationContext, of: TraitDecl.ID, with: TraitDocumentation) throws -> String {
    return ""
}


/// Render the product-type page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: product-type declaration to render page of
///   - with: parsed product-type documentation string
///
/// - Returns: contents of the rendered page
public func renderProductTypePage(ctx: GenerationContext, of: ProductTypeDecl.ID, with: ProductTypeDocumentation) throws -> String {
    return ""
}
