import Foundation
import FrontEnd

func renderSimpleTypeAlias(_ program: TypedProgram, _ n: TypeAliasDecl.ID, _ raw: Bool)
  -> String
{
  let typeAlias = program.ast[n]
  let identifier = typeAlias.identifier.value

  var result = raw ? "typealias" : wrapKeyword("typealias")
  result += " "
  result += raw ? identifier : wrapName(identifier)

  return result
}

func renderSimpleProductType(_ program: TypedProgram, _ n: ProductTypeDecl.ID, _ raw: Bool)
  -> String
{
  let productType = program.ast[n]
  var result = raw ? "type" : wrapKeyword("type")
  result += " "
  result += raw ? productType.baseName : wrapName(productType.baseName)
  return result
}

func renderSimpleBinding(_ program: TypedProgram, _ n: BindingDecl.ID, _ raw: Bool) -> String {
  let binding = program.ast[n]
  let bindingPattern = program.ast[binding.pattern]

  let subpattern = program.ast[NamePattern.ID(bindingPattern.subpattern)]!
  let variable = program.ast[subpattern.decl]
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

func renderSimpleInitializer(_ program: TypedProgram, _ n: InitializerDecl.ID, _ raw: Bool)
  -> String
{
  let initializer = program.ast[n]
  let params = renderSimpleParams(program, initializer.parameters)

  var result = raw ? "init" : wrapKeyword("init")
  let tail = "(\(params))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleFunction(_ program: TypedProgram, _ n: FunctionDecl.ID, _ raw: Bool)
  -> String
{
  let function = program.ast[n]
  let identifier = function.identifier!.value

  var result = ""

  if function.isStatic {
    result += raw ? "static" : wrapKeyword("static")
    result += " "
  }

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(program, function.parameters)))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleMethod(_ program: TypedProgram, _ n: MethodDecl.ID, _ raw: Bool)
  -> String
{
  let method = program.ast[n]
  let identifier = method.identifier.value

  var result = ""

  result += raw ? "fun" : wrapKeyword("fun")
  result += " "
  let tail = "\(identifier)(\(renderSimpleParams(program, method.parameters)))"
  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleSubscript(_ program: TypedProgram, _ n: SubscriptDecl.ID, _ raw: Bool) -> String {
  let sub: SubscriptDecl = program.ast[n]
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
    tail += "(\(renderSimpleParams(program, sub.parameters)))"
  }

  result += raw ? tail : wrapName(tail)

  return result
}

func renderSimpleParams(_ program: TypedProgram, _ ns: [ParameterDecl.ID])
  -> String
{
  var result = ""

  for p in ns {
    result += renderSimpleParam(program, p)
  }

  return result
}

func renderSimpleParam(_ program: TypedProgram, _ n: ParameterDecl.ID) -> String {
  let parameter = program.ast[n]
  let label = getParamLabel(parameter)
  return "\(label):"
}
