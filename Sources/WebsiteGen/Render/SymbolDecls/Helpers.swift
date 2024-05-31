import Foundation
import FrontEnd

func getParamLabel(_ parameter: ParameterDecl) -> String {
  return parameter.label != nil ? parameter.label!.value : "_"
}

func getParamType(_ program: TypedProgram, _ parameter: ParameterDecl) -> String {
  let paramType = program.ast[parameter.annotation!]
  let nameExpr = program.ast[NameExpr.ID(paramType.bareType)]!
  return nameExpr.name.value.stem
}

func getParamConvention(_ program: TypedProgram, _ parameter: ParameterDecl) -> AccessEffect {
  let paramType = program.ast[parameter.annotation!]
  return paramType.convention.value
}

func getOutput(_ program: TypedProgram, _ output: AnyExprID?) -> String? {
  if output == nil {
    return nil
  }

  let d = NameExpr.ID(output!)
  let nameExpr = program.ast[d]!
  return nameExpr.name.value.stem
}

func wrapIndentation(_ count: Int) -> String {
  return wrap("span", "indentation", String(repeating: " ", count: count))
}

func wrapKeyword(_ inner: String) -> String {
  return wrap("span", "keyword", inner)
}

func wrapIdentifier(_ inner: String) -> String {
  return wrap("span", "identifier", inner)
}

func wrapType(_ inner: String) -> String {
  return wrap("a", "type", inner)
}

func wrapName(_ inner: String) -> String {
  return wrap("span", "name", inner)
}

func wrapCodeBlock(_ inner: String) -> String {
  return wrap("div", "code", inner)
}

func wrap(_ element: String, _ className: String, _ inner: String) -> String {
  return "<\(element) class=\"\(className)\">\(inner)</\(element)>"
}
