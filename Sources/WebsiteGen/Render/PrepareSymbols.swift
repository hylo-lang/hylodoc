import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import OrderedCollections

/// Render the associated-type page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-type declaration to render page of
///   - with: parsed associated-type documentation string
///
/// - Returns: contents of the rendered page
public func prepareAssociatedTypePage(
  _ context: GenerationContext, of declId: AssociatedTypeDecl.ID
) throws -> StencilContext {
  let decl: AssociatedTypeDecl = ctx.typedProgram.ast[of]!
  let scope = ctx.typedProgram.nodeToScope[of]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: .symbol(AnyDeclID(of)))
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .decl(AnyDeclID(of)))

  env["pageTitle"] = decl.identifier.value
  env["pageType"] = "Associated Type"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "associated_type_layout.html", context: env)
}

/// Render the associated-value page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-value declaration to render page of
///   - with: parsed associated-value documentation string
///
/// - Returns: contents of the rendered page
public func prepareAssociatedValuePage(
  _ context: GenerationContext, of declId: AssociatedValueDecl.ID
) throws -> StencilContext {
  let decl: AssociatedValueDecl = ctx.typedProgram.ast[of]!
  let scope = ctx.typedProgram.nodeToScope[of]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: .symbol(AnyDeclID(of)))
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .decl(AnyDeclID(of)))

  env["pageTitle"] = decl.identifier.value
  env["pageType"] = "Associated Value"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "associated_value_layout.html", context: env)
}

/// Render the type-alias page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: type-alias declaration to render page of
///   - with: parsed type-alias documentation string
///
/// - Returns: contents of the rendered page
public func prepareTypeAliasPage(
  _ context: GenerationContext, of declId: TypeAliasDecl.ID
) throws -> StencilContext {
  let decl: TypeAliasDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.decl(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]
  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderTypeAliasDecl(ctx.typedProgram, of)
  env["pageType"] = "Type Alias"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTypeAliasDecl(ctx, of, target)

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "type_alias_layout.html", context: env)
}

/// Render the binding page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: binding declaration to render page of
///   - with: parsed binding documentation string
///
/// - Returns: contents of the rendered page
public func prepareBindingPage(
  _ context: GenerationContext, of declId: BindingDecl.ID
) throws -> StencilContext {
  let decl: BindingDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.decl(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = "binding"
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderBindingDecl(ctx.typedProgram, of)
  env["pageType"] = decl.isStatic ? "Static Binding" : "Binding"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderBindingDecl(ctx, of, target)

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["invariants"] = doc.invariants.map { $0.description }.map(htmlGenerator.generate(document:))
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "binding_layout.html", context: env)
}

/// Render the operator page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: operator declaration to render page of
///   - with: parsed operator documentation string
///
/// - Returns: contents of the rendered page
public func prepareOperatorPage(
  _ context: GenerationContext, of declId: OperatorDecl.ID
) throws -> StencilContext {
  let decl: OperatorDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.decl(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.name.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = decl.site.text  // todo
  env["pageType"] = "Operator Introducer"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "operator_layout.html", context: env)
}

/// Render the function page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: function declaration to render page of
///   - with: parsed function documentation string
///
/// - Returns: contents of the rendered page
public func prepareFunctionPage(
  _ context: GenerationContext, of declId: FunctionDecl.ID
) throws -> StencilContext {
  let decl: FunctionDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]
  env["name"] = decl.site.text
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderFunctionDecl(ctx.typedProgram, declId)
  env["pageType"] = "Function"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderFunctionDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description
      .map(htmlGenerator.generate(document:))

    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["returns"] = doc.returns.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "function_layout.html", context: env)
}

/// Render the method page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: method declaration to render page of
///   - with: parsed method documentation string
///
/// - Returns: contents of the rendered page
public func prepareMethodPage(
  _ context: GenerationContext, of declId: MethodDecl.ID
) throws -> StencilContext {
  let decl: MethodDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  // TODO address the case where the function has no name
  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderMethodDecl(ctx.typedProgram, declId)
  env["pageType"] = "Method"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderMethodDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description.map(
      htmlGenerator.generate(document:))
    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["returns"] = doc.returns.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }

    env["members"] = prepareMembersData(
      context,
      referringFrom: target,
      decls: decl.impls.filter { isSupportedDecl(declId: AnyDeclID(member)) }.map { member in
        AnyDeclID(member)
      }
    )

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "method_layout.html", context: env)
}

/// Render the subscript page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: subscript declaration to render page of
///   - with: parsed subscript documentation string
///
/// - Returns: contents of the rendered page
public func prepareSubscriptPage(
  _ context: GenerationContext, of declId: SubscriptDecl.ID
) throws -> StencilContext {
  let decl: SubscriptDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.site.text

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderSubscriptDecl(ctx.typedProgram, declId)
  env["pageType"] = "Subscript"  // todo determine whether it's a subscript or property declaration, if it's the latter, we should display "Property"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderSubscriptDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description.map(
      htmlGenerator.generate(document:))
    env["yields"] = doc.yields.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }
    env["seeAlso"] = doc.documentation.common.common.seeAlso.map(htmlGenerator.generate(document:))
  }
  env["members"] = prepareMembersData(
    context,
    referringFrom: target,
    decls: decl.impls.filter { isSupportedDecl(declId: AnyDeclID(member)) }.map { member in
      AnyDeclID(member)
    }
  )

  return StencilContext(templateName: "subscript_layout.html", context: env)
}

/// Render the initializer page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: initializer declaration to render page of
///   - with: parsed initializer documentation string
///
/// - Returns: contents of the rendered page
public func prepareInitializerPage(
  _ context: GenerationContext, of declId: InitializerDecl.ID
) throws -> StencilContext {
  let decl: InitializerDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  // TODO address the case where the function has no name
  env["name"] = decl.site.text
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderInitializerDecl(ctx.typedProgram, declId)
  env["pageType"] = "Initializer"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderInitializerDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description.map(
      htmlGenerator.generate(document:))

    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        htmlGenerator.generate(document: value.description)
      )
    }

    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "initializer_layout.html", context: env)
}

/// Render the trait page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: trait declaration to render page of
///   - with: parsed trait documentation string
///
/// - Returns: contents of the rendered page
public func prepareTraitPage(
  _ context: GenerationContext, of declId: TraitDecl.ID
)
  throws -> StencilContext
{
  let decl: TraitDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderTraitDecl(ctx.typedProgram, declId)
  env["pageType"] = "Trait"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTraitDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))

    env["invariants"] = doc.invariants.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["seeAlso"] = doc.common.seeAlso.map {
      htmlGenerator.generate(document: $0)
    }
  }

  env["members"] = prepareMembersData(
    context,
    referringFrom: target,
    decls: decl.members.filter(isSupportedDecl)
  )

  return StencilContext(templateName: "trait_layout.html", context: env)
}

/// Render the product-type page
///
/// - Parameters:
///   - context: context for page generation, containing documentation database, ast and stencil templating
///   - of: product-type declaration to render page of
///   - with: parsed product-type documentation string
///
/// - Returns: contents of the rendered page
public func prepareProductTypePage(
  _ context: GenerationContext, of declId: ProductTypeDecl.ID
) throws -> StencilContext {
  let decl: ProductTypeDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: ctx.typedProgram,
      scopeId: scope,
      resolveUrls: referWithSource(ctx.urlResolver, from: target)
    ),
    generator: ctx.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderProductTypeDecl(ctx.typedProgram, declId)
  env["pageType"] = "Product Type"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderProductTypeDecl(ctx, declId, target)

  if let doc = doc {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["invariants"] = doc.invariants.map {
      htmlGenerator.generate(
        document: $0.description)
    }
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  env["members"] = prepareMembersData(
    context,
    referringFrom: target,
    decls: decl.members.filter(isSupportedDecl)
  )

  return StencilContext(templateName: "product_type_layout.html",
    context: env
  )
}
