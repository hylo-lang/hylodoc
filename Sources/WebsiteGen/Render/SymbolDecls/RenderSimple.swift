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
