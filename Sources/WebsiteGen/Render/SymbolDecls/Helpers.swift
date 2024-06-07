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

func getOutputName(_ program: TypedProgram, _ output: AnyExprID?) -> String? {
  if output == nil {
    return nil
  }

  let d = NameExpr.ID(output!)
  let nameExpr: NameExpr = program.ast[d]!
  return nameExpr.name.value.stem
}

func getExprDecl(_ program: TypedProgram, _ expr: AnyExprID?) -> AnyDeclID? {
  if expr == nil {
    return nil
  }

  if let nameExpr = NameExpr.ID(expr!) {
    if let decl = program.referredDecl[nameExpr]?.decl {
      return decl
    }
  }

  return nil
}

func wrapIndentation(_ count: Int) -> String {
  return wrap("span", String(repeating: " ", count: count), className: "indentation")
}

func wrapKeyword(_ inner: String) -> String {
  return wrap("span", inner, className: "keyword")
}

func wrapIdentifier(_ inner: String) -> String {
  return wrap("span", inner, className: "identifier")
}

func wrapType(_ inner: String, href: String? = nil) -> String {
  return wrap(href != nil ? "a" : "span", inner, className: "type", href: href)
}

func wrapLink(_ inner: String, href: String? = nil) -> String {
  if href == nil {
    return inner
  }

  return wrap("a", inner, href: href)
}

func wrapParamName(_ inner: String) -> String {
  return wrap("span", inner, className: "parameter-name")
}

func wrap(_ element: String, _ inner: String, className: String? = nil, href: String? = nil)
  -> String
{
  let link = href != nil ? " href=\"\(href!)\"" : ""
  let classes = className != nil ? " class=\"\(className!)\"" : ""
  return "<\(element)\(classes)\(link)>\(inner)</\(element)>"
}
