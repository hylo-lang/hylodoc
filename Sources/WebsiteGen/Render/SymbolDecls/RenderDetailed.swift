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
