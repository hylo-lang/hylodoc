import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import OrderedCollections

typealias nameAndContent = (name: String, summary: String)
typealias nameAndContentArray = [nameAndContent]

/// Get the members of a declaration
/// - Parameters:
///   - referringFrom:
///   - decls: array of declaration IDs
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
/// - Returns: dictionary with keys as section names and values as arrays of tuples containing name (as an HTML string, including url) and summary of the member
func prepareMembersData(referringFrom: AnyTargetID, decls: [AnyDeclID], ctx: GenerationContext)
  -> [OrderedDictionary<String, nameAndContentArray>.Element]
{
  // the order of the buckets is what determines the order of the sections in the page
  var buckets: OrderedDictionary<String, nameAndContentArray> = [
    "Associated Types": [],
    "Associated Values": [],
    "Type Aliases": [],
    "Bindings": [],
    "Operators": [],
    "Functions": [],
    "Methods": [],
    "Method Implementations": [],
    "Subscripts": [],
    "Subscript Implementations": [],
    "Initializers": [],
    "Traits": [],
    "Product Types": [],
  ]
  let _ = decls.map { declId in
    if let (name, summary, key) = getMemberNameAndSummary(
      ctx: ctx, of: declId, referringFrom: referringFrom)
    {
      buckets[key, default: []].append((name: name, summary: summary ?? ""))
    }
  }
  return buckets.filter { !$0.value.isEmpty }.map { $0 }
}

/// Get the name and summary of a member
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: member declaration to get name and summary of
/// - Returns: name, summary of the member, and key of the section it belongs to in prepareMembersData
func getMemberNameAndSummary(ctx: GenerationContext, of: AnyDeclID, referringFrom: AnyTargetID) -> (
  name: String, summary: String?, key: String
)? {
  switch of.kind {
  // TODO Mark needs to implement this
  // case AssociatedTypeDecl.self:
  //     name = InlineSymbolDeclRenderer.renderAssociatedTypeDecl(AssociatedTypeDecl.ID(of)!)
  //     let docID = AssociatedTypeDecl.ID(of)!
  //     summary = ctx.documentation.symbols.associatedTypeDocs[docID]?.common.summary
  //     key = "Associated Types"
  // TODO Mark needs to implement this
  // case AssociatedValueDecl.self:
  //     name = InlineSymbolDeclRenderer.renderAssociatedValueDecl(AssociatedValueDecl.ID(of)!)
  //     let docID = AssociatedValueDecl.ID(of)!
  //     summary = ctx.documentation.symbols.associatedValueDocs[docID]?.common.summary
  //     key = "Associated Values"
  case TypeAliasDecl.self:
    let declId = TypeAliasDecl.ID(of)!
    let scope = ctx.typedProgram.nodeToScope[declId]!
    return (
      name: InlineSymbolDeclRenderer.renderTypeAliasDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.typeAliasDocs[declId]?.common.summary.map {
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: $0, scopeId: scope, from: ctx.typedProgram)
      },
      key: "Type Aliases"
    )
  case BindingDecl.self:
    let declId = BindingDecl.ID(of)!
    let scope = ctx.typedProgram.nodeToScope[declId]!
    return (
      name: InlineSymbolDeclRenderer.renderBindingDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.bindingDocs[declId]?.common.summary.map {
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: $0, scopeId: scope, from: ctx.typedProgram)
      },
      key: "Bindings"
    )
  // TODO Mark needs to implement this
  // case OperatorDecl.self:
  //     name = InlineSymbolDeclRenderer.renderOperatorDecl(OperatorDecl.ID(of)!)
  //     let docID = OperatorDecl.ID(of)!
  //     summary = ctx.documentation.symbols.operatorDocs[docID]?.documentation.summary
  //     key = "Operators"
  case FunctionDecl.self:
    let declId = FunctionDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderFunctionDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.functionDocs[declId]?.documentation.common.common.summary
        .map {
          ctx.htmlGenerator.generateResolvingHyloReferences(
            document: $0, scopeId: scope, from: ctx.typedProgram)
        },
      key: "Functions"
    )
  case MethodDecl.self:
    let declId = MethodDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderMethodDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.methodDeclDocs[declId]?.documentation.common.common.summary
        .map {
          ctx.htmlGenerator.generateResolvingHyloReferences(
            document: $0, scopeId: scope, from: ctx.typedProgram)
        },
      key: "Methods"
    )
  // not expected to be used, needed for exhaustive switch
  case MethodImpl.self:
    // fatalError("Method implementation should not be rendered")
    return nil
  case SubscriptDecl.self:
    let declId = SubscriptDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderSubscriptDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.subscriptDeclDocs[declId]?.documentation.common.common
        .summary.map {
          ctx.htmlGenerator.generateResolvingHyloReferences(
            document: $0, scopeId: scope, from: ctx.typedProgram)
        },
      key: "Subscripts"
    )
  // not expected to be used, needed for exhaustive switch
  case SubscriptImpl.self:
    // fatalError("Subscript implementation should not be rendered")
    return nil
  case InitializerDecl.self:
    let declId = InitializerDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderInitializerDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.initializerDocs[declId]?.documentation.common.common
        .summary.map {
          ctx.htmlGenerator.generateResolvingHyloReferences(
            document: $0, scopeId: scope, from: ctx.typedProgram)
        },
      key: "Initializers"
    )
  case TraitDecl.self:
    let declId = TraitDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderTraitDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.traitDocs[declId]?.common.summary.map {
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: $0, scopeId: scope, from: ctx.typedProgram)
      },
      key: "Traits"
    )
  case ProductTypeDecl.self:
    let declId = ProductTypeDecl.ID(of)!
    let scope = AnyScopeID(declId)
    return (
      name: InlineSymbolDeclRenderer.renderProductTypeDecl(ctx, declId, referringFrom),
      summary: ctx.documentation.symbols.productTypeDocs[declId]?.common.summary.map {
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: $0, scopeId: scope, from: ctx.typedProgram)
      },
      key: "Product Types"
    )
  default:
    return nil
  }
}

/// Render the associated-type page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-type declaration to render page of
///   - with: parsed associated-type documentation string
///
/// - Returns: contents of the rendered page
public func renderAssociatedTypePage(
  ctx: inout GenerationContext, of: AssociatedTypeDecl.ID, with doc: AssociatedTypeDocumentation?
) throws -> String {
  let decl: AssociatedTypeDecl = ctx.typedProgram.ast[of]!
  let scope = ctx.typedProgram.nodeToScope[of]!

  var env: [String: Any] = [:]

  // TODO address the case where the function has no name
  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

  env["pageTitle"] = decl.identifier.value
  env["pageType"] = "Associated Type"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(
    ctx: &ctx, targetId: .symbol(AnyDeclID(of)), name: "associated_type_layout.html", env: &env)
}

/// Render the associated-value page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: associated-value declaration to render page of
///   - with: parsed associated-value documentation string
///
/// - Returns: contents of the rendered page
public func renderAssociatedValuePage(
  ctx: inout GenerationContext, of: AssociatedValueDecl.ID, with doc: AssociatedValueDocumentation?
) throws -> String {
  let decl: AssociatedValueDecl = ctx.typedProgram.ast[of]!
  let scope = ctx.typedProgram.nodeToScope[of]!

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

  env["pageTitle"] = decl.identifier.value
  env["pageType"] = "Associated Value"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(
    ctx: &ctx, targetId: .symbol(AnyDeclID(of)), name: "associated_value_layout.html", env: &env)
}

/// Render the type-alias page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: type-alias declaration to render page of
///   - with: parsed type-alias documentation string
///
/// - Returns: contents of the rendered page
public func renderTypeAliasPage(
  ctx: inout GenerationContext, of: TypeAliasDecl.ID, with doc: TypeAliasDocumentation?
) throws -> String {
  let decl: TypeAliasDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.symbol(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!

  var env: [String: Any] = [:]
  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderTypeAliasDecl(ctx, of, target)
  env["pageType"] = "Type Alias"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTypeAliasDecl(ctx, of, target)

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "type_alias_layout.html", env: &env)
}

/// Render the binding page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: binding declaration to render page of
///   - with: parsed binding documentation string
///
/// - Returns: contents of the rendered page
public func renderBindingPage(
  ctx: inout GenerationContext, of: BindingDecl.ID, with doc: BindingDocumentation?
) throws -> String {
  let decl: BindingDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.symbol(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!

  var env: [String: Any] = [:]

  env["name"] = "binding"
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderBindingDecl(ctx, of, target)
  env["pageType"] = decl.isStatic ? "Static Binding" : "Binding"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderBindingDecl(ctx, of, target)

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }
    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["invariants"] = doc.invariants.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "binding_layout.html", env: &env)
}

/// Render the operator page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: operator declaration to render page of
///   - with: parsed operator documentation string
///
/// - Returns: contents of the rendered page
public func renderOperatorPage(
  ctx: inout GenerationContext, of: OperatorDecl.ID, with doc: OperatorDocumentation?
) throws -> String {
  let decl: OperatorDecl = ctx.typedProgram.ast[of]!
  let target = AnyTargetID.symbol(AnyDeclID(of))
  let scope = ctx.typedProgram.nodeToScope[of]!

  var env: [String: Any] = [:]

  env["name"] = decl.name.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = decl.site.text  // todo
  env["pageType"] = "Operator Introducer"
  env["declarationPreview"] = decl.site.text  // todo

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }
    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "operator_layout.html", env: &env)
}

/// Render the function page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: function declaration to render page of
///   - with: parsed function documentation string
///
/// - Returns: contents of the rendered page
public func renderFunctionPage(
  ctx: inout GenerationContext, of declId: FunctionDecl.ID, with doc: FunctionDocumentation?
) throws -> String {
  let decl: FunctionDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)

  var env: [String: Any] = [:]
  env["name"] = decl.site.text
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderFunctionDecl(ctx, declId, target)
  env["pageType"] = "Function"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderFunctionDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.documentation.common.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.documentation.common.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["preconditions"] = doc.documentation.common.preconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["returns"] = doc.returns.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "function_layout.html", env: &env)
}

/// Render the method page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: method declaration to render page of
///   - with: parsed method documentation string
///
/// - Returns: contents of the rendered page
public func renderMethodPage(
  ctx: inout GenerationContext, of declId: MethodDecl.ID, with doc: MethodDeclDocumentation?
) throws -> String {
  let decl: MethodDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)

  var env: [String: Any] = [:]

  // TODO address the case where the function has no name
  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderMethodDecl(ctx, declId, target)
  env["pageType"] = "Method"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderMethodDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.documentation.common.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.documentation.common.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["preconditions"] = doc.documentation.common.preconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["returns"] = doc.returns.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }

    // args["members"] = decl.impls.map { member in getMembers(ctx: ctx, of: AnyDeclID(member)) }
    env["members"] = prepareMembersData(
      referringFrom: .symbol(AnyDeclID(declId)),
      decls: decl.impls.map { member in AnyDeclID(member) },
      ctx: ctx)

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "method_layout.html", env: &env)
}

/// Render the subscript page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: subscript declaration to render page of
///   - with: parsed subscript documentation string
///
/// - Returns: contents of the rendered page
public func renderSubscriptPage(
  ctx: inout GenerationContext, of declId: SubscriptDecl.ID, with doc: SubscriptDeclDocumentation?
) throws -> String {
  let decl: SubscriptDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)

  var env: [String: Any] = [:]

  env["name"] = decl.site.text

  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderSubscriptDecl(ctx, declId, target)
  env["pageType"] = "Subscript"  // todo determine whether it's a subscript or property declaration, if it's the latter, we should display "Property"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderSubscriptDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.documentation.common.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.documentation.common.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["yields"] = doc.yields.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }
    env["seeAlso"] = doc.documentation.common.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  // todo this should be displayed very differently, but not designed yet
  env["members"] = prepareMembersData(
    referringFrom: .symbol(AnyDeclID(declId)),
    decls: decl.impls.map { member in AnyDeclID(member) },
    ctx: ctx)

  return try renderTemplate(ctx: &ctx, targetId: target, name: "subscript_layout.html", env: &env)
}

/// Render the initializer page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: initializer declaration to render page of
///   - with: parsed initializer documentation string
///
/// - Returns: contents of the rendered page
public func renderInitializerPage(
  ctx: inout GenerationContext, of declId: InitializerDecl.ID, with doc: InitializerDocumentation?
) throws -> String {
  let decl: InitializerDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)
  var env: [String: Any] = [:]

  // TODO address the case where the function has no name
  env["name"] = decl.site.text
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderInitializerDecl(ctx, declId, target)
  env["pageType"] = "Initializer"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderInitializerDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.documentation.common.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.documentation.common.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["preconditions"] = doc.documentation.common.preconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["postconditions"] = doc.documentation.common.postconditions.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["parameters"] = doc.documentation.parameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }
    env["genericParameters"] = doc.documentation.genericParameters.map { key, value in
      (
        ctx.typedProgram.ast[key].baseName,
        ctx.htmlGenerator.generateResolvingHyloReferences(
          document: value.description, scopeId: scope, from: ctx.typedProgram)
      )
    }

    env["throwsInfo"] = doc.documentation.common.throwsInfo.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["seeAlso"] = doc.documentation.common.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  return try renderTemplate(ctx: &ctx, targetId: target, name: "initializer_layout.html", env: &env)
}

/// Render the trait page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: trait declaration to render page of
///   - with: parsed trait documentation string
///
/// - Returns: contents of the rendered page
public func renderTraitPage(
  ctx: inout GenerationContext, of declId: TraitDecl.ID, with doc: TraitDocumentation?
)
  throws -> String
{
  let decl: TraitDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderTraitDecl(ctx, declId, target)
  env["pageType"] = "Trait"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderTraitDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let details = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: details, scopeId: scope, from: ctx.typedProgram)
    }

    env["invariants"] = doc.invariants.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }

    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  env["members"] = prepareMembersData(
    referringFrom: .symbol(AnyDeclID(declId)), decls: decl.members, ctx: ctx)

  return try renderTemplate(ctx: &ctx, targetId: target, name: "trait_layout.html", env: &env)
}

/// Render the product-type page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: product-type declaration to render page of
///   - with: parsed product-type documentation string
///
/// - Returns: contents of the rendered page
public func renderProductTypePage(
  ctx: inout GenerationContext, of declId: ProductTypeDecl.ID, with doc: ProductTypeDocumentation?
) throws -> String {
  let decl: ProductTypeDecl = ctx.typedProgram.ast[declId]!
  let target = AnyTargetID.symbol(AnyDeclID(declId))
  let scope = AnyScopeID(declId)

  var env: [String: Any] = [:]

  env["name"] = decl.identifier.value
  env["pathToRoot"] = ctx.urlResolver.pathToRoot(target: target)

  env["pageTitle"] = SimpleSymbolDeclRenderer.renderProductTypeDecl(ctx, declId, target)
  env["pageType"] = "Product Type"
  env["declarationPreview"] = BlockSymbolDeclRenderer.renderProductTypeDecl(ctx, declId, target)

  if let doc = doc {
    if let summary = doc.common.summary {
      env["summary"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: summary, scopeId: scope, from: ctx.typedProgram)
    }

    if let block = doc.common.description {
      env["details"] = ctx.htmlGenerator.generateResolvingHyloReferences(
        document: block, scopeId: AnyScopeID(declId), from: ctx.typedProgram)
    }
    env["invariants"] = doc.invariants.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0.description, scopeId: scope, from: ctx.typedProgram)
    }
    env["seeAlso"] = doc.common.seeAlso.map {
      ctx.htmlGenerator.generateResolvingHyloReferences(
        document: $0, scopeId: scope, from: ctx.typedProgram)
    }
  }

  env["members"] = prepareMembersData(
    referringFrom: .symbol(AnyDeclID(declId)), decls: decl.members, ctx: ctx)

  return try renderTemplate(
    ctx: &ctx, targetId: target, name: "product_type_layout.html", env: &env)
}
