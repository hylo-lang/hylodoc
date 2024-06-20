import Foundation

enum RenderString: Equatable {
  enum RenderTag: Equatable {
    case wrap
    case keyword
    case name
    case number
    case type(_ href: String?)
    case link(_ href: String?)

    var tagName: String? {
      switch self {
      case .wrap: return nil
      case .keyword: return "span"
      case .name: return "span"
      case .number: return "span"
      case .type(let href): return href != nil ? "a" : "span"
      case .link(let href): return href != nil ? "a" : nil
      }
    }

    var className: String? {
      switch self {
      case .wrap: return nil
      case .keyword: return "keyword"
      case .name: return "name"
      case .number: return "number-literal"
      case .type: return "type"
      case .link: return nil
      }
    }

    var href: String? {
      switch self {
      case .type(let href): return href
      case .link(let href): return href
      default: return nil
      }
    }
  }

  enum EscapeType {
    case newLine, lessThan, greaterThan

    var text: String {
      switch self {
      case .newLine: return "\n"
      case .lessThan: return "&lt;"
      case .greaterThan: return "&gt;"
      }
    }
  }

  case text(String)
  case escape(EscapeType)
  case indentation(Int)
  case tag(_ name: RenderTag, _ children: [RenderString] = [])
  case error

  func isEmpty() -> Bool {
    return length() <= 0
  }

  func toHTML(_ compressed: Bool = true) -> String {
    let str = compressed ? self.compressed() : self

    switch str {
    case .text(let text):
      return text
    case .escape(let type):
      return type.text
    case .indentation(let count):
      let gap = String(repeating: " ", count: count)
      return "<span class=\"indentation\">\(gap)</span>"
    case .tag(let name, let children):
      let inner = children.map { $0.toHTML() }.joined()

      if let tagName = name.tagName {
        let className = name.className.map { " class=\"\($0)\"" } ?? ""
        let href = name.href.map { " href=\"\($0)\"" } ?? ""
        let openingTag = "<\(tagName)\(className)\(href)>"
        let closingTag = "</\(tagName)>"
        return "\(openingTag)\(inner)\(closingTag)"
      }

      return inner
    case .error:
      return "<span class=\"error\">???</span>"
    }
  }

  func length() -> Int {
    switch self {
    case .text(let text):
      return text.count
    case .escape(_):
      return 1
    case .indentation(let count):
      return count
    case .tag(_, let children):
      return children.map { $0.length() }.reduce(0, +)
    case .error:
      return 3
    }
  }

  func compressed() -> RenderString {
    switch self {
    case .text, .escape, .indentation, .error:
      return self
    case .tag(let name, let children):

      // remove empty children
      let nonEmptyChildren = children.compactMap { $0.compressed() }.filter { !$0.isEmpty() }

      // combine consecutive elements of the same type
      let combinedChildren = RenderString.combineConsecutiveElements(nonEmptyChildren) {
        current, next in
        if case .text(let text1) = current, case .text(let text2) = next {
          return .text(text1 + text2)
        } else if case .indentation(let count1) = current, case .indentation(let count2) = next {
          return .indentation(count1 + count2)
        } else {
          return nil  // Return nil if no combination is possible
        }
      }

      // unwrap if only 1 child
      if case .wrap = name, combinedChildren.count == 1 {
        return combinedChildren[0]
      }

      // return empty wrap if empty tag
      if combinedChildren.isEmpty {
        return .wrap()
      }

      return .tag(name, combinedChildren)
    }
  }

  static func combineConsecutiveElements(
    _ elements: [RenderString], combine: (RenderString, RenderString) -> RenderString?
  ) -> [RenderString] {
    var result: [RenderString] = []

    var iterator = elements.makeIterator()
    guard var current = iterator.next() else { return result }

    while let next = iterator.next() {
      if let combined = combine(current, next) {
        current = combined
      } else {
        result.append(current)
        current = next
      }
    }

    result.append(current)
    return result
  }

  static func tag(_ name: RenderTag, _ text: String) -> RenderString {
    return .tag(name, [.text(text)])
  }

  static func wrap(_ children: [RenderString] = []) -> RenderString {
    return .tag(.wrap, children)
  }

  static func wrap(_ text: String) -> RenderString {
    return .tag(.wrap, [.text(text)])
  }

  static func keyword(_ children: [RenderString] = []) -> RenderString {
    return .tag(.keyword, children)
  }

  static func keyword(_ text: String) -> RenderString {
    return .tag(.keyword, [.text(text)])
  }

  static func name(_ children: [RenderString] = []) -> RenderString {
    return .tag(.name, children)
  }

  static func name(_ text: String) -> RenderString {
    return .tag(.name, [.text(text)])
  }

  static func number(_ children: [RenderString] = []) -> RenderString {
    return .tag(.number, children)
  }

  static func number(_ text: String) -> RenderString {
    return .tag(.number, [.text(text)])
  }

  static func link(_ children: [RenderString] = [], href: String?) -> RenderString {
    return .tag(.link(href), children)
  }

  static func link(_ text: String, href: String?) -> RenderString {
    return .tag(.link(href), [.text(text)])
  }

  static func type(_ children: [RenderString] = [], href: String?) -> RenderString {
    return .tag(.type(href), children)
  }

  static func type(_ text: String, href: String?) -> RenderString {
    return .tag(.type(href), [.text(text)])
  }

  static func join(_ list: [RenderString], _ separator: RenderString) -> RenderString {
    var elements: [RenderString] = []
    for (i, v) in list.enumerated() {
      elements.append(v)
      if i < list.count - 1 {
        elements.append(separator)
      }
    }
    return .wrap(elements)
  }

  static func join(_ list: [RenderString], _ separator: String = ", ") -> RenderString {
    return join(list, .text(separator))
  }

  static func += (lhs: inout RenderString, rhs: RenderString) {
    if case .tag(let name, var children) = lhs {
      children.append(rhs)
      lhs = .tag(name, children)
    }
  }

  static func += (lhs: inout RenderString, rhs: String) {
    if case .tag(let name, var children) = lhs {
      children.append(.text(rhs))
      lhs = .tag(name, children)
    }
  }

  static func == (lhs: RenderString, rhs: RenderString) -> Bool {
    return lhs.compressed().isEqual(to: rhs.compressed())
  }

  private func isEqual(to other: RenderString) -> Bool {
    switch (self, other) {
    case (.text(let text1), .text(let text2)):
      return text1 == text2
    case (.escape(let type1), .escape(let type2)):
      return type1 == type2
    case (.indentation(let count1), .indentation(let count2)):
      return count1 == count2
    case (.tag(let name1, let children1), .tag(let name2, let children2)):
      return name1 == name2 && children1 == children2
    default:
      return false
    }
  }
}
