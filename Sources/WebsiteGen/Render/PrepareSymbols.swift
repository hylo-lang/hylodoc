import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import OrderedCollections

func sourceUrlOf(_ decl: any Node) -> URL {
  decl.site.file.url
}
func sourceUrlOf(_ decl: some Node) -> URL {
  decl.site.file.url
}

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
  let decl: AssociatedTypeDecl = context.documentation.typedProgram.ast[declId]!
  let scope = context.documentation.typedProgram.nodeToScope[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Associated Type"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = context.documentation.documentation.symbols.associatedTypeDocs[declId] {
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
  let decl: AssociatedValueDecl = context.documentation.typedProgram.ast[declId]!
  let scope = context.documentation.typedProgram.nodeToScope[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Associated Value"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = context.documentation.documentation.symbols.associatedValueDocs[declId] {
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
  let scope = context.documentation.typedProgram.nodeToScope[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(context.documentation.typedProgram.ast[declId]),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Type Alias"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTypeAliasDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.typeAliasDocs[declId] {
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
  let decl: BindingDecl = context.documentation.typedProgram.ast[declId]!
  let scope = context.documentation.typedProgram.nodeToScope[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = decl.isStatic ? "Static Binding" : "Binding"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderBindingDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.bindingDocs[declId] {
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
  let decl: OperatorDecl = context.documentation.typedProgram.ast[declId]!
  let scope = context.documentation.typedProgram.nodeToScope[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Operator Introducer"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderOperatorDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.operatorDocs[declId] {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  return StencilContext(templateName: "operator_layout.html", context: env)
}

/// If there is at least one parameter documented, we render all parameters. Otherwise, we render nothing.
func allOrNothing<T: SingleEntityDecl>(documentation: [T.ID: Block], parameters: [T.ID], ast: AST)
  -> [(name: String, description: Block)]
{
  if documentation.isEmpty {
    return []
  }
  return parameters.map { parameterId in
    (
      ast[parameterId].baseName,
      documentation[parameterId] ?? Block.document([])
    )
  }
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
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Function"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderFunctionDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.functionDocs[declId] {
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
    env["complexityInfo"] = doc.documentation.common.complexityInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    // TODO: https://gitlab.ewi.tudelft.nl/cse2000-software-project/2023-2024/cluster-e/04d/automated-documentation-generation-tool/-/issues/147
    env["parameters"] = allOrNothing(
      documentation: doc.documentation.parameters, parameters: decl.parameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["genericParameters"] = allOrNothing(
      documentation: doc.documentation.genericParameters, parameters: decl.genericParameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
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
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Method"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderMethodDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.methodDeclDocs[declId] {
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
    env["complexityInfo"] = doc.documentation.common.complexityInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = allOrNothing(
      documentation: doc.documentation.parameters, parameters: decl.parameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["genericParameters"] = allOrNothing(
      documentation: doc.documentation.genericParameters, parameters: decl.genericParameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["members"] = prepareMembersData(
      context,
      referringFrom: target,
      decls: convertTargetsToDecls(context.documentation.targetResolver[target]!.children)
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
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Subscript"  // todo determine whether it's a subscript or property declaration, if it's the latter, we should display "Property"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderSubscriptDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.subscriptDeclDocs[declId] {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description.map(
      htmlGenerator.generate(document:))
    env["yields"] = doc.yields.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["projectsInfo"] = doc.projectsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["complexityInfo"] = doc.documentation.common.complexityInfo.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = allOrNothing(
      documentation: doc.documentation.parameters, parameters: decl.parameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["genericParameters"] = allOrNothing(
      documentation: doc.documentation.genericParameters, parameters: decl.genericParameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map(htmlGenerator.generate(document:))
  }
  env["members"] = prepareMembersData(
    context,
    referringFrom: target,
    decls: convertTargetsToDecls(context.documentation.targetResolver[target]!.children)
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
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Initializer"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderInitializerDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.initializerDocs[declId] {
    env["summary"] = doc.documentation.common.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.documentation.common.common.description.map(
      htmlGenerator.generate(document:))

    env["preconditions"] = doc.documentation.common.preconditions.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      htmlGenerator.generate(document: $0.description)
    }

    env["parameters"] = allOrNothing(
      documentation: doc.documentation.parameters, parameters: decl.parameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["genericParameters"] = allOrNothing(
      documentation: doc.documentation.genericParameters, parameters: decl.genericParameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      htmlGenerator.generate(document: $0.description)
    }
    env["complexityInfo"] = doc.documentation.common.complexityInfo.map {
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
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Trait"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTraitDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.traitDocs[declId] {
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
    decls: convertTargetsToDecls(context.documentation.targetResolver[target]!.children)
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
  let target = AnyTargetID.decl(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  let decl = context.documentation.typedProgram.ast[declId]!
  let htmlGenerator = SimpleHTMLGenerator(
    context: ReferenceRenderingContext(
      typedProgram: context.documentation.typedProgram,
      scopeId: scope,
      resolveUrls: targetToUrl(context.documentation.targetResolver),
      sourceUrl: sourceUrlOf(decl),
      assetStore: context.documentation.documentation.assets
    ),
    generator: context.htmlGenerator
  )

  var env: [String: Any] = [:]

  env["pageType"] = "Product Type"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderProductTypeDecl(
    context.documentation, declId)

  if let doc = context.documentation.documentation.symbols.productTypeDocs[declId] {
    env["summary"] = doc.common.summary.map(htmlGenerator.generate(document:))
    env["details"] = doc.common.description.map(htmlGenerator.generate(document:))
    env["invariants"] = doc.invariants.map {
      htmlGenerator.generate(
        document: $0.description)
    }
    env["genericParameters"] = allOrNothing(
      documentation: doc.genericParameters, parameters: decl.genericParameters,
      ast: context.documentation.typedProgram.ast
    )
    .map { ($0, htmlGenerator.generate(document: $1)) }

    env["seeAlso"] = doc.common.seeAlso.map(htmlGenerator.generate(document:))
  }

  env["members"] = prepareMembersData(
    context,
    referringFrom: target,
    decls: convertTargetsToDecls(context.documentation.targetResolver[target]!.children)
  )

  return StencilContext(
    templateName: "product_type_layout.html",
    context: env
  )
}
