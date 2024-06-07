import Foundation
import FrontEnd

func renderSimpleTrait(
  _ ctx: GenerationContext, _ n: TraitDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let trait = ctx.typedProgram.ast[n]
  let identifier = trait.identifier.value

  var result = raw ? "trait" : wrapKeyword("trait")
  result += " "
  result += raw ? identifier : wrapParamName(identifier)

  return result
}

func renderSimpleTypeAlias(
  _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let typeAlias = ctx.typedProgram.ast[n]
  let identifier = typeAlias.identifier.value

  var result = raw ? "typealias" : wrapKeyword("typealias")
  result += " "
  result += raw ? identifier : wrapParamName(identifier)

  return result
}

func renderSimpleProductType(
  _ ctx: GenerationContext, _ n: ProductTypeDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let productType = ctx.typedProgram.ast[n]
  var result = raw ? "type" : wrapKeyword("type")
  result += " "
  result += raw ? productType.baseName : wrapParamName(productType.baseName)
  return result
}

func renderSimpleBinding(
  _ ctx: GenerationContext, _ n: BindingDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
) -> String {
  let binding = ctx.typedProgram.ast[n]
  let bindingPattern = ctx.typedProgram.ast[binding.pattern]

  let subpattern = ctx.typedProgram.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = ctx.typedProgram.ast[subpattern.decl]
  let introducer = String(describing: bindingPattern.introducer.value)

  var result = ""
  if binding.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }
  result += raw ? introducer : wrapKeyword(introducer)
  result += " "
  result += raw ? variable.baseName : wrapParamName(variable.baseName)

  return result
}

func renderSimpleInitializer(
  _ ctx: GenerationContext, _ n: InitializerDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let initializer = ctx.typedProgram.ast[n]
  let params = renderSimpleParams(ctx, initializer.parameters, referringFrom)

  var result = raw ? "init" : wrapKeyword("init")
  let tail = "(\(params))"
  result += raw ? tail : wrapParamName(tail)

  return result
}

func renderSimpleFunction(
  _ ctx: GenerationContext, _ n: FunctionDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let function = ctx.typedProgram.ast[n]
  let identifier = function.identifier!.value

  var result = ""

  if function.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(ctx, function.parameters, referringFrom)))"
  result += raw ? tail : wrapParamName(tail)

  return result
}

func renderSimpleMethod(
  _ ctx: GenerationContext, _ n: MethodDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let method = ctx.typedProgram.ast[n]
  let identifier = method.identifier.value

  var result = ""

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(ctx, method.parameters, referringFrom)))"
  result += raw ? tail : wrapParamName(tail)

  return result
}

func renderSimpleSubscript(
  _ ctx: GenerationContext, _ n: SubscriptDecl.ID, _ raw: Bool, _ referringFrom: AnyTargetID
) -> String {
  let sub: SubscriptDecl = ctx.typedProgram.ast[n]
  var result = ""

  if sub.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }

  let introducer = String(describing: sub.introducer.value)
  result += raw ? introducer : wrapKeyword(introducer)

  var tail = ""
  if let identifier = sub.identifier {
    tail += " \(identifier.value)"
  }

  if sub.introducer.value == SubscriptDecl.Introducer.subscript {
    tail += "(\(renderSimpleParams(ctx, sub.parameters, referringFrom)))"
  }

  result += raw ? tail : wrapParamName(tail)

  return result
}

func renderSimpleParams(
  _ ctx: GenerationContext, _ ns: [ParameterDecl.ID], _ referringFrom: AnyTargetID
)
  -> String
{
  var result = ""

  for p in ns {
    result += renderSimpleParam(ctx, p, referringFrom)
  }

  return result
}

func renderSimpleParam(
  _ ctx: GenerationContext, _ n: ParameterDecl.ID, _ referringFrom: AnyTargetID
)
  -> String
{
  let parameter: ParameterDecl = ctx.typedProgram.ast[n]
  let label = getParamLabel(parameter)
  return "\(label):"
}
