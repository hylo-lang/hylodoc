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
