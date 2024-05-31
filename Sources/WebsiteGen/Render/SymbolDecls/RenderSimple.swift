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
