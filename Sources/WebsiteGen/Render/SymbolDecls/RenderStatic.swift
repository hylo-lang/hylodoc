import Foundation
import FrontEnd

func renderSimpleTrait(
  _ typedProgram: TypedProgram, _ n: TraitDecl.ID, _ raw: Bool
)
  -> String
{
  let trait = typedProgram.ast[n]
  let identifier = trait.identifier.value

  var result = raw ? "trait" : wrapKeyword("trait")
  result += " "
  result += raw ? identifier : wrapName(identifier)

  return result
}

func renderSimpleTypeAlias(
  _ typedProgram: TypedProgram, _ n: TypeAliasDecl.ID, _ raw: Bool
)
  -> String
{
  let typeAlias = typedProgram.ast[n]
  let identifier = typeAlias.identifier.value

  var result = raw ? "typealias" : wrapKeyword("typealias")
  result += " "
  result += raw ? identifier : wrapName(identifier)

  return result
}

func renderSimpleProductType(
  _ typedProgram: TypedProgram, _ n: ProductTypeDecl.ID, _ raw: Bool
)
  -> String
{
  let productType = typedProgram.ast[n]
  var result = raw ? "type" : wrapKeyword("type")
  result += " "
  result += raw ? productType.baseName : wrapName(productType.baseName)
  return result
}

func renderSimpleBinding(
  _ typedProgram: TypedProgram, _ n: BindingDecl.ID, _ raw: Bool
) -> String {
  let binding = typedProgram.ast[n]
  let bindingPattern = typedProgram.ast[binding.pattern]

  let subpattern = typedProgram.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = typedProgram.ast[subpattern.decl]
  let introducer = String(describing: bindingPattern.introducer.value)

  var result = ""
  if binding.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }
  result += raw ? introducer : wrapKeyword(introducer)
  result += " "
  result += raw ? variable.baseName : wrapName(variable.baseName)

  return result
}

func renderSimpleInitializer(
  _ typedProgram: TypedProgram, _ n: InitializerDecl.ID, _ raw: Bool
)
  -> String
{
  let initializer = typedProgram.ast[n]
  let params = renderSimpleParams(typedProgram, initializer.parameters)

  var result = raw ? "init" : wrapKeyword("init")
  let tail = "(\(params))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleFunction(
  _ typedProgram: TypedProgram, _ n: FunctionDecl.ID, _ raw: Bool
)
  -> String
{
  let function = typedProgram.ast[n]
  let identifier = function.identifier!.value

  var result = ""

  if function.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(typedProgram, function.parameters)))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleMethod(
  _ typedProgram: TypedProgram, _ n: MethodDecl.ID, _ raw: Bool
)
  -> String
{
  let method = typedProgram.ast[n]
  let identifier = method.identifier.value

  var result = ""

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(typedProgram, method.parameters)))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleSubscript(
  _ typedProgram: TypedProgram, _ n: SubscriptDecl.ID, _ raw: Bool
) -> String {
  let sub: SubscriptDecl = typedProgram.ast[n]
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
    tail += "(\(renderSimpleParams(typedProgram, sub.parameters)))"
  }

  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleParams(
  _ typedProgram: TypedProgram, _ ns: [ParameterDecl.ID]
)
  -> String
{
  var result = ""

  for p in ns {
    result += renderSimpleParam(typedProgram, p)
  }

  return result
}

func renderSimpleParam(
  _ typedProgram: TypedProgram, _ n: ParameterDecl.ID
)
  -> String
{
  let parameter: ParameterDecl = typedProgram.ast[n]
  let label = getParamLabel(parameter)
  return "\(label):"
}
