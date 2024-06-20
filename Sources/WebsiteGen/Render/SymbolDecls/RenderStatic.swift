import Foundation
import FrontEnd

func renderSimpleOperator(
  _ typedProgram: TypedProgram, _ n: OperatorDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let op: OperatorDecl = typedProgram.ast[n]
  let notation = String(describing: op.notation.value)
  let name = op.name.value

  var result: RenderString = raw ? .wrap() : .wrap([.keyword("operator"), .text(" ")])
  result += raw ? .text(notation) : .keyword(notation)
  result += raw ? .text(name) : .name(name)

  return result
}

func renderSimpleTrait(
  _ typedProgram: TypedProgram, _ n: TraitDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let trait = typedProgram.ast[n]
  let identifier = trait.identifier.value

  var result: RenderString = raw ? .wrap() : .wrap([.keyword("trait"), .text(" ")])
  result += raw ? .text(identifier) : .name(identifier)

  return result
}

func renderSimpleTypeAlias(
  _ typedProgram: TypedProgram, _ n: TypeAliasDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let typeAlias = typedProgram.ast[n]
  let identifier = typeAlias.identifier.value

  var result: RenderString = raw ? .wrap() : .wrap([.keyword("typealias"), .text(" ")])
  result += raw ? .text(identifier) : .name(identifier)

  return result
}

func renderSimpleProductType(
  _ typedProgram: TypedProgram, _ n: ProductTypeDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let productType = typedProgram.ast[n]
  let identifier = productType.baseName

  var result: RenderString = raw ? .wrap() : .wrap([.keyword("type"), .text(" ")])
  result += raw ? .text(identifier) : .name(identifier)

  return result
}

func renderSimpleBinding(
  _ typedProgram: TypedProgram, _ n: BindingDecl.ID, _ raw: Bool
) -> RenderString {
  let binding = typedProgram.ast[n]
  let bindingPattern = typedProgram.ast[binding.pattern]

  let subpattern = typedProgram.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = typedProgram.ast[subpattern.decl]
  let introducer = String(describing: bindingPattern.introducer.value)
  let identifier = variable.baseName

  var result: RenderString = .wrap()

  if !raw {
    if binding.isStatic {
      result += .wrap([.keyword("static"), .text(" ")])
    }

    result += .wrap([.keyword(introducer), .text(" ")])
  }

  result += raw ? .text(identifier) : .name(identifier)

  return result
}

func renderSimpleInitializer(
  _ typedProgram: TypedProgram, _ n: InitializerDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let initializer = typedProgram.ast[n]
  let params = renderSimpleParams(typedProgram, initializer.parameters)

  var result: RenderString = raw ? .text("init") : .keyword("init")
  result += raw ? params : .name([params])

  return result
}

func renderSimpleFunction(
  _ typedProgram: TypedProgram, _ n: FunctionDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let function = typedProgram.ast[n]
  let identifier = function.identifier!.value

  var result: RenderString = .wrap()

  if !raw {
    if function.isStatic {
      result += .wrap([.keyword("static"), .text(" ")])
    }

    result += .wrap([.keyword("fun"), .text(" ")])
  }

  let params = renderSimpleParams(typedProgram, function.parameters)
  let tail: RenderString = .wrap([.text(identifier), params])
  result += raw ? tail : .name([tail])

  return result
}

func renderSimpleMethod(
  _ typedProgram: TypedProgram, _ n: MethodDecl.ID, _ raw: Bool
)
  -> RenderString
{
  let method = typedProgram.ast[n]
  let identifier = method.identifier.value

  var result: RenderString = .wrap()

  if !raw {
    result += .wrap([.keyword("fun"), .text(" ")])
  }

  let params = renderSimpleParams(typedProgram, method.parameters)
  let tail: RenderString = .wrap([.text(identifier), params])
  result += raw ? tail : .name([tail])

  return result
}

func renderSimpleSubscript(
  _ typedProgram: TypedProgram, _ n: SubscriptDecl.ID, _ raw: Bool
) -> RenderString {
  let sub: SubscriptDecl = typedProgram.ast[n]
  let introducer = String(describing: sub.introducer.value)
  let identifier = sub.identifier?.value

  var result: RenderString = .wrap()
  var tail: RenderString = .wrap()

  if !raw {
    if sub.isStatic {
      result += .wrap([.keyword("static"), .text(" ")])
    }

    result += .keyword(introducer)

    if identifier != nil {
      tail += .wrap([.text(" "), .name(identifier!)])
    }
  } else {
    if identifier != nil {
      result += identifier!
    } else {
      result += introducer
    }
  }

  if sub.introducer.value == SubscriptDecl.Introducer.subscript {
    tail += renderSimpleParams(typedProgram, sub.parameters)
  }

  result += raw ? tail : .name([tail])

  return result
}

func renderSimpleParams(
  _ typedProgram: TypedProgram, _ ns: [ParameterDecl.ID]
)
  -> RenderString
{
  let params = ns.map { p in
    renderSimpleParam(typedProgram, p)
  }

  return .wrap([.text("("), .join(params, ""), .text(")")])
}

func renderSimpleParam(
  _ typedProgram: TypedProgram, _ n: ParameterDecl.ID
)
  -> RenderString
{
  let parameter: ParameterDecl = typedProgram.ast[n]
  let label = getParamLabel(parameter)

  return .wrap([.text(label), .text(":")])
}
