import Foundation
import FrontEnd

func renderDetailedTrait(
  _ ctx: GenerationContext, _ n: TraitDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let trait = ctx.typedProgram.ast[n]
  let identifier = trait.identifier.value
  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  let result = wrapLink("\(wrapKeyword("trait")) \(identifier)", href: symbolUrl)

  return result
}

func renderDetailedTypeAlias(
  _ ctx: GenerationContext, _ n: TypeAliasDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let typeAlias = ctx.typedProgram.ast[n]
  let identifier = typeAlias.identifier.value
  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  var result = wrapLink("\(wrapKeyword("typealias")) \(identifier)", href: symbolUrl)

  if let wrappedType = renderDetailedType(ctx, typeAlias.aliasedType, referringFrom) {
    result += " = \(wrappedType)"
  }

  return result
}

func renderDetailedProductType(
  _ ctx: GenerationContext, _ n: ProductTypeDecl.ID,
  _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let productType = ctx.typedProgram.ast[n]
  let identifier = productType.identifier.value
  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  var result = wrapLink("\(wrapKeyword("type")) \(identifier)", href: symbolUrl)
  let baseLength = productType.baseName.count + 8

  if !productType.conformances.isEmpty {
    result += " : "

    let nameExpr = productType.conformances[0]
    result += renderDetailedType(ctx, AnyExprID(nameExpr), referringFrom)!

    for i in (1..<productType.conformances.count) {
      result += ","
      result += inline ? " " : "\n\(wrapIndentation(baseLength))"

      let nameExpr = productType.conformances[i]
      result += renderDetailedType(ctx, AnyExprID(nameExpr), referringFrom)!
    }
  }

  return result
}

func renderDetailedBinding(
  _ ctx: GenerationContext, _ n: BindingDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
) -> String {
  let binding = ctx.typedProgram.ast[n]
  let bindingPattern = ctx.typedProgram.ast[binding.pattern]

  let subpattern = ctx.typedProgram.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = ctx.typedProgram.ast[subpattern.decl]

  let introducer = String(describing: bindingPattern.introducer.value)
  var result = ""

  if binding.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  let identifier = variable.baseName
  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  result += "\(wrapKeyword(introducer)) \(identifier)"
  result = wrapLink(result, href: symbolUrl)

  if let typeWrapped = renderDetailedType(ctx, bindingPattern.annotation, referringFrom) {
    result += ": \(typeWrapped)"
  }

  return result
}

func renderDetailedInitializer(
  _ ctx: GenerationContext, _ n: InitializerDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let initializer = ctx.typedProgram.ast[n]
  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  var result = wrapLink(wrapKeyword("init"), href: symbolUrl)
  result += "(\(renderDetailedParams(ctx, initializer.parameters, inline, referringFrom)))"

  return result
}

func renderDetailedFunction(
  _ ctx: GenerationContext, _ n: FunctionDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let function = ctx.typedProgram.ast[n]
  let identifier = function.identifier!.value
  var result = ""

  if function.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  result += "\(wrapKeyword("fun")) \(identifier)"
  result = wrapLink(result, href: symbolUrl)
  result += "(\(renderDetailedParams(ctx, function.parameters, inline, referringFrom)))"

  if let output = renderDetailedType(ctx, function.output, referringFrom) {
    result += " -> \(output)"
  }

  let effect =
    function.receiverEffect != nil ? String(describing: function.receiverEffect!.value) : "let"

  result += " { \(wrapKeyword(effect)) }"

  return result
}

func renderDetailedMethod(
  _ ctx: GenerationContext, _ n: MethodDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let method = ctx.typedProgram.ast[n]
  let identifier = method.identifier.value
  var result = ""

  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description

  result += wrapLink("\(wrapKeyword("fun")) \(identifier)", href: symbolUrl)
  result += "(\(renderDetailedParams(ctx, method.parameters, inline, referringFrom)))"

  if let output = renderDetailedType(ctx, method.output, referringFrom) {
    result += " -> \(output)"
  }

  result += " { "

  for (i, impl) in method.impls.enumerated() {
    let implementation = ctx.typedProgram.ast[impl]
    let effect = String(describing: implementation.introducer.value)

    result += wrapKeyword(effect)
    result += i < method.impls.count - 1 ? ", " : " "
  }

  result += "}"

  return result
}

func renderDetailedSubscript(
  _ ctx: GenerationContext, _ n: SubscriptDecl.ID, _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  let sub: SubscriptDecl = ctx.typedProgram.ast[n]
  var result = ""

  if sub.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  result += wrapKeyword(String(describing: sub.introducer.value))

  if let identifier = sub.identifier {
    result += " \(identifier.value)"
  }

  let symbolUrl = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(n)))?.description
  result = wrapLink(result, href: symbolUrl)

  if sub.introducer.value == SubscriptDecl.Introducer.subscript {
    result += "(\(renderDetailedParams(ctx, sub.parameters, inline, referringFrom)))"
  }

  if let output = renderDetailedType(ctx, sub.output, referringFrom) {
    result += ": \(output)"
  }

  result += " { "

  for (i, impl) in sub.impls.enumerated() {
    let implementation = ctx.typedProgram.ast[impl]
    let effect = String(describing: implementation.introducer.value)

    result += wrapKeyword(effect)
    result += i < sub.impls.count - 1 ? ", " : " "
  }

  result += "}"

  return result
}

func renderDetailedParams(
  _ ctx: GenerationContext, _ ns: [ParameterDecl.ID], _ inline: Bool, _ referringFrom: AnyTargetID
)
  -> String
{
  var result = ""

  for (i, p) in ns.enumerated() {
    if !inline && ns.count > 1 {
      result += "\n\(wrapIndentation(3))"
    }

    result += renderDetailedParam(ctx, p, referringFrom)

    if i < ns.count - 1 {
      result += ","

      if inline && i < ns.count - 1 {
        result += " "
      }
    }
  }

  if !inline && ns.count > 1 {
    result += "\n"
  }

  return result
}

func renderDetailedParam(
  _ ctx: GenerationContext, _ n: ParameterDecl.ID, _ referringFrom: AnyTargetID
) -> String {
  let parameter = ctx.typedProgram.ast[n]
  let label = getParamLabel(parameter)
  let name = parameter.baseName
  let type = getParamType(ctx.typedProgram, parameter)
  let convention = getParamConvention(ctx.typedProgram, parameter)

  var result = label
  if name != label {
    result += " \(wrapParamName(name))"
  }

  if let typeWrapped = renderDetailedType(ctx, type, referringFrom) {
    result += ":"

    if convention != AccessEffect.let {
      result += " \(wrapKeyword(String(describing: convention)))"
    }

    result += " \(typeWrapped)"
  }

  return result
}

func renderDetailedType(
  _ ctx: GenerationContext, _ type: AnyExprID?, _ referringFrom: AnyTargetID
)
  -> String?
{
  if let name = getTypeName(ctx.typedProgram, type) {
    var url: String? = nil

    if let decl = getExprDecl(ctx.typedProgram, type) {
      url = ctx.urlResolver.refer(from: referringFrom, to: .symbol(AnyDeclID(decl)))?.description
    }

    return wrapType(name, href: url)
  }

  return nil
}
