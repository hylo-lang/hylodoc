import Foundation
import FrontEnd

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
