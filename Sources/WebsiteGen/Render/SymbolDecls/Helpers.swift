import Foundation
import FrontEnd

func getParamLabel(_ parameter: ParameterDecl) -> String {
  return parameter.label != nil ? parameter.label!.value : "_"
}

func getParamType(_ program: TypedProgram, _ parameter: ParameterDecl) -> AnyExprID {
  let paramType = program.ast[parameter.annotation!]
  return paramType.bareType
}

func getParamConvention(_ program: TypedProgram, _ parameter: ParameterDecl) -> AccessEffect {
  let paramType = program.ast[parameter.annotation!]
  return paramType.convention.value
}

func getTypeName(_ program: TypedProgram, _ type: AnyExprID?) -> String? {
  if type == nil {
    return nil
  }

  let d = NameExpr.ID(type!)
  return getTypeName(program, d)
}

func getTypeName(_ program: TypedProgram, _ type: NameExpr.ID?) -> String? {
  if type == nil {
    return nil
  }

  let nameExpr: NameExpr = program.ast[type]!
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

func wrapType(_ inner: String, href: URL? = nil) -> String {
  return wrap(href != nil ? "a" : "span", inner, className: "type", href: href)
}

func wrapLink(_ inner: String, href: URL? = nil) -> String {
  if href == nil {
    return inner
  }

  return wrap("a", inner, href: href)
}

func wrapName(_ inner: String) -> String {
  return wrap("span", inner, className: "name")
}

func wrap(_ element: String, _ inner: String, className: String? = nil, href: URL? = nil)
  -> String
{
  let link = href != nil ? " href=\"\(urlToEncodedPath(href!))\"" : ""
  let classes = className != nil ? " class=\"\(className!)\"" : ""
  return "<\(element)\(classes)\(link)>\(inner)</\(element)>"
}

func getDeclUrl(_ ctx: DocumentationContext, _ to: AnyDeclID?)
  -> String?
{
  if let to = to {
    if let url = ctx.targetResolver.url(to: .decl(to)) {
      return urlToEncodedPath(url)
    }
  }

  return nil
}

func isSelfParam(_ program: TypedProgram, _ parameter: ParameterDecl) -> Bool {
  if let annotation = program.ast[parameter.annotation] {
    if let nameID = NameExpr.ID(annotation.bareType) {
      let nameExpr = program.ast[nameID]
      return nameExpr.name.value.stem == "Self"
    }
  }

  return false
}

func getNameExprDecl(_ program: TypedProgram, _ expr: NameExpr.ID) -> AnyDeclID? {
  return program.referredDecl[expr]?.decl
}
