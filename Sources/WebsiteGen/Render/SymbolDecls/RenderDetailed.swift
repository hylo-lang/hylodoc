import Foundation
import FrontEnd

func renderDetailedTypeAlias(_ program: TypedProgram, _ n: TypeAliasDecl.ID, _ inline: Bool)
  -> String
{
  let typeAlias = program.ast[n]
  let identifier = typeAlias.identifier.value

  var result = "\(wrapKeyword("typealias")) \(identifier) = "

  let nameExpr = program.ast[NameExpr.ID(typeAlias.aliasedType)]!
  result += wrapType(nameExpr.name.value.stem)

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedProductType(_ program: TypedProgram, _ n: ProductTypeDecl.ID, _ inline: Bool)
  -> String
{
  let productType = program.ast[n]
  var result = "\(wrapKeyword("type")) \(productType.baseName)"
  let baseLength = productType.baseName.count + 8

  if !productType.conformances.isEmpty {
    result += " : "

    let nameExpr = program.ast[productType.conformances[0]]
    result += wrapType(nameExpr.name.value.stem)

    for i in (1..<productType.conformances.count) {
      result += ","
      result += inline ? " " : "\n\(wrapIndentation(baseLength))"

      let nameExpr = program.ast[productType.conformances[i]]
      result += wrapType(nameExpr.name.value.stem)
    }
  }

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedBinding(_ program: TypedProgram, _ n: BindingDecl.ID, _ inline: Bool) -> String {
  let binding = program.ast[n]
  let bindingPattern = program.ast[binding.pattern]

  let subpattern = program.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = program.ast[subpattern.decl]

  let introducer = String(describing: bindingPattern.introducer.value)
  var result = ""

  if binding.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  result += "\(wrapKeyword(introducer)) \(variable.baseName)"

  if bindingPattern.annotation != nil, let d = NameExpr.ID(bindingPattern.annotation!) {
    let nameExpr = program.ast[d]
    let name = String(describing: nameExpr.name.value)
    result += ": \(wrapType(name))"
  }

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedInitializer(_ program: TypedProgram, _ n: InitializerDecl.ID, _ inline: Bool)
  -> String
{
  let initializer = program.ast[n]
  var result = wrapKeyword("init")
  result += "(\(renderDetailedParams(program, initializer.parameters, inline)))"

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedFunction(_ program: TypedProgram, _ n: FunctionDecl.ID, _ inline: Bool)
  -> String
{
  let function = program.ast[n]
  let identifier = function.identifier!.value
  var result = ""

  if function.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  result += "\(wrapKeyword("fun")) \(identifier)"
  result += "(\(renderDetailedParams(program, function.parameters, inline)))"

  if let output = getOutput(program, function.output) {
    result += " -> \(wrapType(output))"
  }

  let effect =
    function.receiverEffect != nil ? String(describing: function.receiverEffect!.value) : "let"

  result += " { \(wrapKeyword(effect)) }"

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedMethod(_ program: TypedProgram, _ n: MethodDecl.ID, _ inline: Bool)
  -> String
{
  return ""
}

func renderDetailedSubscript(_ program: TypedProgram, _ n: SubscriptDecl.ID, _ inline: Bool)
  -> String
{
  let sub: SubscriptDecl = program.ast[n]

  var result = ""

  if sub.isStatic {
    result += "\(wrapKeyword("static")) "
  }

  result += wrapKeyword("subscript")

  if let identifier = sub.identifier {
    result += " \(identifier.value)"
  }

  result += "(\(renderDetailedParams(program, sub.parameters, inline)))"

  if let output = getOutput(program, sub.output) {
    result += ": \(wrapType(output))"
  }

  result += " { "

  for (i, impl) in sub.impls.enumerated() {
    let implementation = program.ast[impl]
    let effect = String(describing: implementation.introducer.value)

    result += wrapKeyword(effect)
    result += i < sub.impls.count - 1 ? ", " : " "
  }

  result += "}"

  return inline ? result : wrapCodeBlock(result)
}

func renderDetailedParams(_ program: TypedProgram, _ ns: [ParameterDecl.ID], _ inline: Bool)
  -> String
{
  var result = ""

  for (i, p) in ns.enumerated() {
    if !inline && ns.count > 1 {
      result += "\n\(wrapIndentation(3))"
    }

    result += renderDetailedParam(program, p)

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

func renderDetailedParam(_ program: TypedProgram, _ n: ParameterDecl.ID) -> String {
  let parameter = program.ast[n]
  let label = getParamLabel(parameter)
  let name = parameter.baseName
  let type = getParamType(program, parameter)
  let convention = getParamConvention(program, parameter)

  var result = label
  if name != label {
    result += " \(wrapName(name))"
  }

  result += ":"

  if convention != AccessEffect.let {
    result += " \(wrapKeyword(String(describing: convention)))"
  }

  result += " \(wrapType(type))"
  return result
}
