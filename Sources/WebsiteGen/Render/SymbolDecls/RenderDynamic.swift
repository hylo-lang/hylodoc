import Foundation
import FrontEnd

func renderDetailedOperator(
  _ ctx: DocumentationContext, _ n: OperatorDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let op: OperatorDecl = ctx.typedProgram.ast[n]
  let notation = String(describing: op.notation.value)
  let name = op.name.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .link(
    [.keyword("operator"), .text(" "), .keyword(notation), .text(name)], href: typeUrl)

  if let precedenceGroup = op.precedenceGroup {
    let group = String(describing: precedenceGroup.value)
    result += .wrap([.text(" : "), .keyword(group)])
  }

  return result
}

func renderDetailedTrait(
  _ ctx: DocumentationContext, _ n: TraitDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let trait = ctx.typedProgram.ast[n]
  let identifier = trait.identifier.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  let result: RenderString = .link([.keyword("trait"), .text(" \(identifier)")], href: typeUrl)

  return result
}

func renderDetailedTypeAlias(
  _ ctx: DocumentationContext, _ n: TypeAliasDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let typeAlias = ctx.typedProgram.ast[n]
  let identifier = typeAlias.identifier.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))
  let aliasedType = renderDetailedType(ctx, typeAlias.aliasedType)

  let result: RenderString = .wrap([
    .link([.keyword("typealias"), .text(" \(identifier)")], href: typeUrl),
    .text(" = "), aliasedType,
  ])

  return result
}

func renderDetailedType(
  _ ctx: DocumentationContext, _ type: AnyExprID
)
  -> RenderString
{
  return renderDetailedType(ctx, ctx.typedProgram[type].type)
}

func renderDetailedType(
  _ ctx: DocumentationContext, _ type: AnyDeclID
)
  -> RenderString
{
  return renderDetailedType(ctx, ctx.typedProgram[type].type)
}

func renderDetailedProductType(
  _ ctx: DocumentationContext, _ n: ProductTypeDecl.ID,
  _ inline: Bool
)
  -> RenderString
{
  let productType: ProductTypeDecl = ctx.typedProgram.ast[n]
  let identifier = productType.identifier.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .wrap([
    .link([.keyword("type"), .text(" \(identifier)")], href: typeUrl)
  ])

  if let generic = renderDetailedGenericClause(ctx, productType.genericClause?.value) {
    result += generic
  }

  let baseLength = result.length()

  if !productType.conformances.isEmpty {
    let conformances: [RenderString] = productType.conformances.map { c in
      return renderDetailedType(ctx, AnyExprID(c))
    }

    let separator: RenderString =
      inline ? .text(", ") : .wrap([.text(","), .escape(.newLine), .indentation(baseLength + 2)])
    result += .wrap([.text(": "), .join(conformances, separator)])
  }

  return result
}

func renderDetailedBinding(
  _ ctx: DocumentationContext, _ n: BindingDecl.ID, _ inline: Bool
) -> RenderString {
  let binding = ctx.typedProgram.ast[n]
  let bindingPattern = ctx.typedProgram.ast[binding.pattern]

  let subpattern = ctx.typedProgram.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = ctx.typedProgram.ast[subpattern.decl]
  let identifier = variable.baseName

  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))
  let introducer = String(describing: bindingPattern.introducer.value)
  let annotation = renderDetailedType(ctx, AnyDeclID(n))

  var result: RenderString = .link(href: typeUrl)

  if binding.isStatic {
    result += .wrap([.keyword("static"), .text(" ")])
  }

  result += .wrap([.keyword(introducer), .text(" \(identifier)")])
  result = .wrap([result])
  result += .wrap([.text(": "), annotation])

  return result
}

func renderDetailedInitializer(
  _ ctx: DocumentationContext, _ n: InitializerDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let initializer = ctx.typedProgram.ast[n]
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .wrap([.link([.keyword("init")], href: typeUrl)])

  if let generic = renderDetailedGenericClause(ctx, initializer.genericClause?.value) {
    result += generic
  }

  result += renderDetailedParams(ctx, initializer.parameters, inline)

  return result
}

func renderDetailedFunction(
  _ ctx: DocumentationContext, _ n: FunctionDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let function: FunctionDecl = ctx.typedProgram.ast[n]
  let identifier = function.identifier!.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .link(href: typeUrl)

  if function.isStatic {
    result += .wrap([.keyword("static"), .text(" ")])
  }

  result += .wrap([.keyword("fun"), .text(" \(identifier)")])
  result = .wrap([result])

  if let generic = renderDetailedGenericClause(ctx, function.genericClause?.value) {
    result += generic
  }

  result += renderDetailedParams(ctx, function.parameters, inline)

  if let outputID = function.output {
    let output = renderDetailedType(ctx, outputID)
    result += .wrap([.text(" -> "), output])
  }

  if let receiverEffect = function.receiverEffect?.value {
    let effect = String(describing: receiverEffect)
    result += .wrap([.text(" { "), .keyword(effect), .text(" }")])
  }

  return result
}

func renderDetailedMethod(
  _ ctx: DocumentationContext, _ n: MethodDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let method = ctx.typedProgram.ast[n]
  let identifier = method.identifier.value
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .wrap([
    .link([.keyword("fun"), .text(" \(identifier)")], href: typeUrl)
  ])

  if let generic = renderDetailedGenericClause(ctx, method.genericClause?.value) {
    result += generic
  }

  result += renderDetailedParams(ctx, method.parameters, inline)

  if let outputID = method.output {
    let output = renderDetailedType(ctx, outputID)
    result += .wrap([.text(" -> "), output])
  }

  let effects: [RenderString] = method.impls.map { i in
    let implementation = ctx.typedProgram.ast[i]
    let effect = String(describing: implementation.introducer.value)
    return .keyword(effect)
  }

  result += .wrap([.text(" { "), .join(effects), .text(" }")])

  return result
}

func renderDetailedSubscript(
  _ ctx: DocumentationContext, _ n: SubscriptDecl.ID, _ inline: Bool
)
  -> RenderString
{
  let sub: SubscriptDecl = ctx.typedProgram.ast[n]
  let introducer = String(describing: sub.introducer.value)
  let typeUrl = getDeclUrl(ctx, AnyDeclID(n))

  var result: RenderString = .link(href: typeUrl)

  if sub.isStatic {
    result += .wrap([.keyword("static"), .text(" ")])
  }

  result += .keyword(introducer)
  if let identifier = sub.identifier?.value {
    result += " \(identifier)"
  }

  result = .wrap([result])

  if let generic = renderDetailedGenericClause(ctx, sub.genericClause?.value) {
    result += generic
  }

  if sub.introducer.value == SubscriptDecl.Introducer.subscript {
    result += renderDetailedParams(ctx, sub.parameters, inline)
  }

  let output = renderDetailedType(ctx, sub.output)
  result += .wrap([.text(": "), output])

  let effects: [RenderString] = sub.impls.map { i in
    let implementation = ctx.typedProgram.ast[i]
    let effect = String(describing: implementation.introducer.value)
    return .keyword(effect)
  }

  result += .wrap([.text(" { "), .join(effects), .text(" }")])

  return result
}

func renderDetailedParams(
  _ ctx: DocumentationContext, _ ns: [ParameterDecl.ID], _ inline: Bool
)
  -> RenderString
{
  let parameters: [RenderString] = ns.map { p in renderDetailedParam(ctx, p) }

  let indentation: RenderString = .wrap([.escape(.newLine), .indentation(3)])
  let breakLines = !inline && ns.count > 1
  let separator: RenderString =
    breakLines ? .wrap([.text(","), indentation]) : .text(", ")

  var result: RenderString = .join(parameters, separator)

  if breakLines {
    result = .wrap([indentation, result, .escape(.newLine)])
  }

  result = .wrap([.text("("), result, .text(")")])
  return result
}

func renderDetailedParam(
  _ ctx: DocumentationContext, _ n: ParameterDecl.ID
) -> RenderString {
  let parameter: ParameterDecl = ctx.typedProgram.ast[n]
  let label = getParamLabel(parameter)
  let name = parameter.baseName
  let convention = getParamConvention(ctx.typedProgram, parameter)

  var result: RenderString = .wrap([.text(label)])
  if name != label {
    result += .wrap([.text(" "), .name(name)])
  }

  result += ":"

  if convention != AccessEffect.let {
    result += .wrap([.text(" "), .keyword(String(describing: convention))])
  }

  let isSelf = isSelfParam(ctx.typedProgram, parameter)
  let annotation: RenderString =
    isSelf ? .type("Self", href: nil) : renderDetailedType(ctx, AnyDeclID(n))
  result += .wrap([.text(" "), annotation])

  return result
}

func renderDetailedWhere(
  _ ctx: DocumentationContext, _ whereClause: WhereClause?
)
  -> RenderString?
{
  if whereClause == nil {
    return nil
  }

  let constraints: [RenderString] = whereClause!.constraints.compactMap { c in
    switch c.value {
    case .equality(let l, let r):
      let identifier = ctx.typedProgram.ast[l].name.value.stem
      if let n = NameExpr.ID(r) {
        let name = ctx.typedProgram.ast[n]
        let other = name.name.value.stem

        let typeDecl = getNameExprDecl(ctx.typedProgram, n)
        let typeUrl = getDeclUrl(ctx, typeDecl)

        return .wrap([.name(identifier), .text(" == "), .type(other, href: typeUrl)])
      }

      return nil  // TODO
    case .bound(let l, let r):
      let identifier = ctx.typedProgram.ast[l].name.value.stem
      let conformances: [RenderString] = r.compactMap { c in
        if let n = NameExpr.ID(c) {
          let name = ctx.typedProgram.ast[n]

          let typeDecl = getNameExprDecl(ctx.typedProgram, n)
          let typeUrl = getDeclUrl(ctx, typeDecl)

          return .type(name.name.value.stem, href: typeUrl)
        }

        return nil  // TODO
      }
      return .wrap([.name(identifier), .text(": "), .join(conformances, " & ")])
    case .value(_):
      return nil  // TODO
    }
  }

  if constraints.isEmpty {
    return nil
  }

  return .wrap([.keyword("where"), .text(" "), .join(constraints)])
}

func renderDetailedGenericClause(
  _ ctx: DocumentationContext, _ genericClause: GenericClause?
)
  -> RenderString?
{
  if genericClause == nil {
    return nil
  }

  let parameters: [RenderString] = genericClause!.parameters.map { p in
    let d = ctx.typedProgram.ast[p]
    let genericIdentifier = d.identifier.value

    let conformances: [RenderString] = d.conformances.map { c in
      let typeDecl = getNameExprDecl(ctx.typedProgram, c)
      let typeUrl = getDeclUrl(ctx, typeDecl)

      return .type(getTypeName(ctx.typedProgram, AnyExprID(c))!, href: typeUrl)
    }

    if conformances.isEmpty {
      return .name(genericIdentifier)
    } else {
      return .wrap([.name(genericIdentifier), .text(": "), .join(conformances, " & ")])
    }
  }

  if !parameters.isEmpty {
    var result: RenderString = .wrap([.escape(.lessThan), .join(parameters)])

    if let whereClause = renderDetailedWhere(ctx, genericClause!.whereClause?.value) {
      result += .wrap([.text(" "), whereClause])
    }

    result += .escape(.greaterThan)
    return result
  }

  return nil
}

func renderDetailedCompileTimeValue(
  _ ctx: DocumentationContext, _ value: CompileTimeValue
)
  -> RenderString
{
  switch value {
  case .type(let t):
    return renderDetailedType(ctx, t)
  case .compilerKnown(let t):
    return .number(t.description)
  }
}

func renderDetailedType(_ ctx: DocumentationContext, _ type: AnyType)
  -> RenderString
{
  if let t = TypeAliasType(type) {
    let typeUrl = getDeclUrl(ctx, AnyDeclID(t.decl))
    return .type(t.name.value, href: typeUrl)
  }

  if let t = ProductType(type) {
    let typeUrl = getDeclUrl(ctx, AnyDeclID(t.decl))
    return .type(t.name.value, href: typeUrl)
  }

  if let t: BufferType = BufferType(type) {
    let elementType = renderDetailedType(ctx, t.element)
    let count = renderDetailedCompileTimeValue(ctx, t.count)
    return .wrap([elementType, .text("["), count, .text("]")])
  }

  if let t = TupleType(type) {
    let elementTypes: [RenderString] = t.elements.map { e in
      let elementType = renderDetailedType(ctx, e.type)
      if e.label != nil {
        return .wrap([.name(e.label!), .text(": "), elementType])
      } else {
        return elementType
      }
    }
    return .wrap([.text("("), .join(elementTypes), .text(")")])
  }

  if let t = GenericTypeParameterType(type) {
    return .name(t.name.value)
  }

  if let t = ParameterType(type) {
    return renderDetailedType(ctx, t.bareType)
  }

  if let t = MetatypeType(type) {
    return renderDetailedType(ctx, t.instance)
  }

  if let t = BoundGenericType(type) {
    let base = renderDetailedType(ctx, t.base)
    let arguments: [RenderString] = t.arguments.values.map {
      renderDetailedCompileTimeValue(ctx, $0)
    }

    let generic: RenderString = .wrap([.escape(.lessThan), .join(arguments), .escape(.greaterThan)])

    switch t.base.base {
    case is ProductType, is TypeAliasType:
      return .wrap([base, generic])
    default:
      return .wrap([generic, base])
    }
  }

  if let t = UnionType(type) {
    if t.elements.isEmpty {
      return .name("Never")
    }

    let elements = t.elements.map { e in
      renderDetailedType(ctx, e)
    }

    return .wrap([.name("Union"), .escape(.lessThan), .join(elements), .escape(.greaterThan)])
  }

  if let t = TraitType(type) {
    let typeUrl = getDeclUrl(ctx, AnyDeclID(t.decl))
    return .type(t.name.value, href: typeUrl)
  }

  if let t = ArrowType(type) {
    let inputs: [RenderString] = t.inputs.map { i in
      var result: RenderString = i.label != nil ? .wrap([.name(i.label!), .text(" : ")]) : .wrap()
      result += renderDetailedType(ctx, i.type)
      return result
    }

    let receiverEffect = String(describing: t.receiverEffect)
    let environment = renderDetailedType(ctx, t.environment)
    let output = renderDetailedType(ctx, t.output)

    return .wrap([
      .text("["), environment, .text("] "),
      .text("("), .join(inputs), .text(") "),
      .keyword(receiverEffect), .text(" -> "), output,
    ])
  }

  if let t = ExistentialType(type) {
    return .text(t.description)
  }

  // if let _ = AssociatedTypeType(type) {
  //   return .text("ASSOCIATED TYPE")
  // }

  // if let _ = AssociatedValueType(type) {
  //   return .text("ASSOCIATED VALUE")
  // }

  // if let _ = NamespaceType(type) {
  //   return .text("NAMESPACE")
  // }

  // if let _ = RemoteType(type) {
  //   return .text("REMOTE")
  // }

  // if let _ = WitnessType(type) {
  //   return .text("WITNESS")
  // }

  return .error
}
