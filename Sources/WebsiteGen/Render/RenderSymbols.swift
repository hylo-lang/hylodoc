import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit

func prepareMembersData(referringFrom: AnyTargetID, decls: [AnyDeclID], ctx: GenerationContext) -> [(name: String, url: String)] {
  decls.map { declId in 
    return (
      getMembers(ctx: ctx, of: declId).name,
      ctx.urlResolver.refer(
        from: referringFrom,
        to: .symbol(AnyDeclID(declId))
      )?.description ?? ""
    )
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
public func renderAssociatedTypePage(ctx: GenerationContext, of: AssociatedTypeDecl.ID, with doc: AssociatedTypeDocumentation?) throws -> String {
    let decl: AssociatedTypeDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    // TODO address the case where the function has no name
    args["name"] = decl.identifier.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.identifier.value
    args["pageType"] = "Associated Type"
    args["declarationPreview"] = decl.site.text // todo
    
    if let doc = doc {
      // Summary
      if let summary = doc.common.summary {
        args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["seeAlso"] = doc.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    
    return try ctx.stencil.renderTemplate(name: "associated_type_layout.html", context: args)
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
  ctx: GenerationContext, of: AssociatedValueDecl.ID, with doc: AssociatedValueDocumentation?
) throws -> String {
  let decl: AssociatedValueDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    args["name"] = decl.identifier.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.identifier.value
    args["pageType"] = "Associated Value"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      // Summary
      if let summary = doc.common.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["seeAlso"] = doc.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }

    return try ctx.stencil.renderTemplate(name: "associated_value_layout.html", context: args)
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
  ctx: GenerationContext, of: TypeAliasDecl.ID, with doc: TypeAliasDocumentation?
) throws -> String {
  let decl: TypeAliasDecl = ctx.typedProgram.ast[of]!

  var args: [String: Any] = [:]
  args["name"] = decl.identifier.value
  args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

  args["pageTitle"] = decl.identifier.value // todo
  args["pageType"] = "Type Alias"
  args["declarationPreview"] = decl.site.text // todo

  if let doc = doc {
    // Summary
    if let summary = doc.common.summary {
      args["summary"] = HtmlGenerator.standard.generate(doc: summary)
    }

    // Details
    if let block = doc.common.description {
      args["details"] = HtmlGenerator.standard.generate(doc: block)
    }
  }
  return try ctx.stencil.renderTemplate(name: "type_alias_layout.html", context: args)
}

/// Render the binding page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: binding declaration to render page of
///   - with: parsed binding documentation string
///
/// - Returns: contents of the rendered page
public func renderBindingPage(ctx: GenerationContext, of: BindingDecl.ID, with doc: BindingDocumentation?) throws -> String {
    let decl: BindingDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    args["name"] = "binding"
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = decl.isStatic ? "Static Binding" : "Binding"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      if let summary = doc.common.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }
      if let block = doc.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["invariants"] = doc.invariants.map { HtmlGenerator.standard.generate(doc: $0.description) }

      args["seeAlso"] = doc.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    return try ctx.stencil.renderTemplate(name: "binding_layout.html", context: args)
}

/// Render the operator page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: operator declaration to render page of
///   - with: parsed operator documentation string
///
/// - Returns: contents of the rendered page
public func renderOperatorPage(ctx: GenerationContext, of: OperatorDecl.ID, with doc: OperatorDocumentation?) throws -> String {
    let decl: OperatorDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    // TODO address the case where the function has no name
    args["name"] = decl.name.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Operator Introducer"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      // Summary
      if let summary = doc.documentation.summary {
        args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.documentation.description {
        args["details"] = HtmlGenerator.standard.generate(doc: block)
      }
      args["seeAlso"] = doc.documentation.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }


    return try ctx.stencil.renderTemplate(name: "operator_layout.html", context: args)
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
  ctx: GenerationContext, of: FunctionDecl.ID, with doc: FunctionDocumentation?
) throws -> String {
  let decl: FunctionDecl = ctx.typedProgram.ast[of]!

  var args: [String: Any] = [:]

  args["name"] = decl.site.text
  args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

  args["pageTitle"] = decl.site.text // todo
  args["pageType"] = "Function"
  args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
    // Summary
    if let summary = doc.documentation.common.summary {
      args["summary"] = HtmlGenerator.standard.generate(doc: summary)
    }

    // Details
    if let block = doc.documentation.common.description {
      args["details"] = HtmlGenerator.standard.generate(doc: block)
    }

    args["preconditions"] = doc.documentation.preconditions.map {
      HtmlGenerator.standard.generate(doc: $0.description)
    }
    args["postconditions"] = doc.documentation.postconditions.map {
      HtmlGenerator.standard.generate(doc: $0.description)
    }

    if let returns = doc.documentation.returns {
      switch returns {
      case .always(let block):
        args["returns"] = [HtmlGenerator.standard.generate(doc: block)]
      case .cases(let blocks):
        args["returns"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
      }
    }
    if let throwsInfo = doc.documentation.throwsInfo {
      switch throwsInfo {
      case .generally(let block):
        args["throwsInfo"] = [HtmlGenerator.standard.generate(doc: block)]
      case .cases(let blocks):
        args["throwsInfo"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
      }
    }

    args["parameters"] = doc.documentation.parameters.mapValues {
      HtmlGenerator.standard.generate(doc: $0.description)
    }
    args["genericParameters"] = doc.documentation.genericParameters.mapValues {
      HtmlGenerator.standard.generate(doc: $0.description)
    }

    args["seeAlso"] = doc.documentation.common.seeAlso.map {
      HtmlGenerator.standard.generate(doc: $0)
    }
  }

  return try ctx.stencil.renderTemplate(name: "function_layout.html", context: args)
}

/// Render the method page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: method declaration to render page of
///   - with: parsed method documentation string
///
/// - Returns: contents of the rendered page
public func renderMethodPage(ctx: GenerationContext, of: MethodDecl.ID, with doc: MethodDeclDocumentation?) throws -> String {
    let decl: MethodDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    // TODO address the case where the function has no name
    args["name"] = decl.identifier.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Method"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      // Summary
      if let summary = doc.documentation.common.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.documentation.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["preconditions"] = doc.documentation.preconditions.map { HtmlGenerator.standard.generate(doc: $0.description) }
      args["postconditions"] = doc.documentation.postconditions.map { HtmlGenerator.standard.generate(doc: $0.description) }

      if let returns = doc.documentation.returns {
          switch returns {
          case .always(let block):
              args["returns"] = [HtmlGenerator.standard.generate(doc: block)]
          case .cases(let blocks):
              args["returns"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
          }
      }
      if let throwsInfo = doc.documentation.throwsInfo {
          switch throwsInfo {
          case .generally(let block):
              args["throwsInfo"] = [HtmlGenerator.standard.generate(doc: block)]
          case .cases(let blocks):
              args["throwsInfo"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
          }
      }

      args["parameters"] = doc.documentation.parameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }
      args["genericParameters"] = doc.documentation.genericParameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }

      args["members"] = decl.impls.map { member in getMembers(ctx: ctx, of: AnyDeclID(member)) }
      
      args["seeAlso"] = doc.documentation.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    return try ctx.stencil.renderTemplate(name: "method_layout.html", context: args)
}

/// Render the method-implementation page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: method-implementation declaration to render page of
///   - with: parsed method-implementation documentation string
///
/// - Returns: contents of the rendered page
public func renderMethodImplementationPage(
  ctx: GenerationContext, of: MethodImpl.ID, with doc: MethodImplDocumentation?
) throws -> String {
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
public func renderSubscriptPage(ctx: GenerationContext, of: SubscriptDecl.ID, with doc: SubscriptDeclDocumentation?) throws -> String {
    let decl: SubscriptDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    args["name"] = decl.site.text
    
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Subscript" // todo determine whether it's a subscript or property declaration, if it's the latter, we should display "Property"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc { 
      // Summary
      if let summary = doc.documentation.generalDescription.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.documentation.generalDescription.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      if let yields = doc.documentation.yields {
          switch yields {
          case .always(let block):
              args["yields"] = [HtmlGenerator.standard.generate(doc: block)]
          case .cases(let blocks):
              args["yields"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
          }
      }
      if let throwsInfo = doc.documentation.throwsInfo {
          switch throwsInfo {
          case .generally(let block):
              args["throwsInfo"] = [HtmlGenerator.standard.generate(doc: block)]
          case .cases(let blocks):
              args["throwsInfo"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
          }
      }

      args["parameters"] = doc.documentation.parameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }
      args["genericParameters"] = doc.documentation.genericParameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }      
      args["seeAlso"] = doc.documentation.generalDescription.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    args["members"] = decl.impls.map { member in getMembers(ctx: ctx, of: AnyDeclID(member)) }

    return try ctx.stencil.renderTemplate(name: "subscript_layout.html", context: args)
}

/// Render the subscript-implementation page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: subscript-implementation declaration to render page of
///   - with: parsed subscript-implementation documentation string
///
/// - Returns: contents of the rendered page
public func renderSubscriptImplementationPage(
  ctx: GenerationContext, of: SubscriptImpl.ID, with doc: SubscriptImplDocumentation?
) throws -> String {
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
public func renderInitializerPage(ctx: GenerationContext, of: InitializerDecl.ID, with doc: InitializerDocumentation?) throws -> String {
    let decl: InitializerDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    // TODO address the case where the function has no name
    args["name"] = decl.site.text
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))
    
    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Initializer"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      // Summary
      if let summary = doc.common.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      // Details
      if let block = doc.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["preconditions"] = doc.preconditions.map { HtmlGenerator.standard.generate(doc: $0.description) }
      args["postconditions"] = doc.postconditions.map { HtmlGenerator.standard.generate(doc: $0.description) }

      args["parameters"] = doc.parameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }
      args["genericParameters"] = doc.genericParameters.mapValues { HtmlGenerator.standard.generate(doc: $0.description) }

      if let throwsInfo = doc.throwsInfo {
          switch throwsInfo {
          case .generally(let block):
              args["throwsInfo"] = [HtmlGenerator.standard.generate(doc: block)]
          case .cases(let blocks):
              args["throwsInfo"] = blocks.map { HtmlGenerator.standard.generate(doc: $0) }
          }
      }
      
      args["seeAlso"] = doc.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    return try ctx.stencil.renderTemplate(name: "initializer_layout.html", context: args)
}

/// Render the trait page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: trait declaration to render page of
///   - with: parsed trait documentation string
///
/// - Returns: contents of the rendered page
public func renderTraitPage(ctx: GenerationContext, of: TraitDecl.ID, with doc: TraitDocumentation?) throws -> String {
    let decl: TraitDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    args["name"] = decl.identifier.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Trait"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      if let summary = doc.common.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      if let block = doc.common.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }

      args["invariants"] = doc.invariants.map { HtmlGenerator.standard.generate(doc: $0.description) }

      args["seeAlso"] = doc.common.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }

    args["members"] = prepareMembersData(referringFrom: .symbol(AnyDeclID(of)), decls: decl.members, ctx: ctx)

    return try ctx.stencil.renderTemplate(name: "trait_layout.html", context: args)
}

/// Render the product-type page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: product-type declaration to render page of
///   - with: parsed product-type documentation string
///
/// - Returns: contents of the rendered page
public func renderProductTypePage(ctx: GenerationContext, of: ProductTypeDecl.ID, with doc: ProductTypeDocumentation?) throws -> String {
    let decl: ProductTypeDecl = ctx.typedProgram.ast[of]!

    var args: [String : Any] = [:]

    args["name"] = decl.identifier.value
    args["pathToRoot"] = ctx.urlResolver.pathToRoot(target: .symbol(AnyDeclID(of)))

    args["pageTitle"] = decl.site.text // todo
    args["pageType"] = "Product Type"
    args["declarationPreview"] = decl.site.text // todo

    if let doc = doc {
      if let summary = doc.generalDescription.summary {
          args["summary"] = HtmlGenerator.standard.generate(doc: summary)
      }

      if let block = doc.generalDescription.description {
          args["details"] = HtmlGenerator.standard.generate(doc: block)
      }
      args["invariants"] = doc.invariants.map { HtmlGenerator.standard.generate(doc: $0.description) }
      args["seeAlso"] = doc.generalDescription.seeAlso.map { HtmlGenerator.standard.generate(doc: $0) }
    }
    
    args["members"] = prepareMembersData(referringFrom: .symbol(AnyDeclID(of)), decls: decl.members, ctx: ctx)

    return try ctx.stencil.renderTemplate(name: "product_type_layout.html", context: args)
}

func getMembers(ctx: GenerationContext, of: AnyDeclID) -> (name: String, summary: Block?) {
    switch of.kind {
    case AssociatedTypeDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! AssociatedTypeDecl
        let name = astDecl.identifier.value
        let docID = AssociatedTypeDecl.ID(of)!
        let summary = ctx.documentation.symbols.associatedTypeDocs[docID]?.common.summary
        return (name, summary)
    case AssociatedValueDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! AssociatedValueDecl
        let name = astDecl.identifier.value
        let docID = AssociatedValueDecl.ID(of)!
        let summary = ctx.documentation.symbols.associatedValueDocs[docID]?.common.summary
        return (name, summary)
    case TypeAliasDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! TypeAliasDecl
        let name = astDecl.identifier.value
        let docID = TypeAliasDecl.ID(of)!
        let summary = ctx.documentation.symbols.typeAliasDocs[docID]?.common.summary
        return (name, summary)
    // temporary, need Mark's code to handle this
    case BindingDecl.self:
        let name = "binding"
        let summary: Block? = nil
        return (name, summary)
    case OperatorDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! OperatorDecl
        let name = astDecl.name.value
        let docID = OperatorDecl.ID(of)!
        let summary = ctx.documentation.symbols.operatorDocs[docID]?.documentation.summary
        return (name, summary)
    case FunctionDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! FunctionDecl
        let name = astDecl.identifier?.value ?? "function"
        let docID = FunctionDecl.ID(of)!
        let summary = ctx.documentation.symbols.functionDocs[docID]?.documentation.common.summary
        return (name, summary)
    case MethodDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! MethodDecl
        let name = astDecl.identifier.value
        let docID = MethodDecl.ID(of)!
        let summary = ctx.documentation.symbols.methodDeclDocs[docID]?.documentation.common.summary
        return (name, summary)
    // not expected to be used, needed for exhaustive switch
    case MethodImpl.self:
        let name = "methodImpl"
        let summary: Block? = nil
        return (name, summary)
        // fatalError("Method implementation should not be rendered")
    case SubscriptDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! SubscriptDecl
        let name = astDecl.identifier?.value ?? "subscript(_:)"
        let docID = SubscriptDecl.ID(of)!
        let summary = ctx.documentation.symbols.subscriptDeclDocs[docID]?.documentation.generalDescription.summary
        return (name, summary)
    // not expected to be used, needed for exhaustive switch
    case SubscriptImpl.self:
        let name = "subscriptImpl"
        let summary: Block? = nil
        return (name, summary)
        // fatalError("Subscript implementation should not be rendered")
    case InitializerDecl.self:
        let name = "init"
        let docID = InitializerDecl.ID(of)!
        let summary = ctx.documentation.symbols.initializerDocs[docID]?.common.summary
        return (name, summary)
    case TraitDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! TraitDecl
        let name = astDecl.identifier.value
        let docID = TraitDecl.ID(of)!
        let summary = ctx.documentation.symbols.traitDocs[docID]?.common.summary
        return (name, summary)
    case ProductTypeDecl.self:
        let astDecl = ctx.typedProgram.ast[of]! as! ProductTypeDecl
        let name = astDecl.identifier.value
        let docID = ProductTypeDecl.ID(of)!
        let summary = ctx.documentation.symbols.productTypeDocs[docID]?.generalDescription.summary
        return (name, summary)
    default:
        return ("", nil)
    }
}