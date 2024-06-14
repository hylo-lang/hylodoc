import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest
import WebsiteGen

/// Check if string contains array of sub-strings only separated by whitespaces
/// - Parameters:
///   - pattern: array of strings to be matched inside res
///   - res: string in which to search for sub-strings in pattern
/// - Returns: true if res is a valid string for regex, and all sub-strings in pattern are found in res in the same order and separated by whitespaces or newlines, false otherwise
func matchWithWhitespacesInBetween(pattern: [String], in res: String) -> Bool {
  do {
    let pattern = pattern.map { NSRegularExpression.escapedPattern(for: $0) }.joined(
      separator: "\\s*")
    let adjustedPattern = "(?s)" + pattern
    let regex = try NSRegularExpression(pattern: adjustedPattern)

    let range = NSRange(location: 0, length: res.utf16.count)
    if let _ = regex.firstMatch(in: res, options: [], range: range) {
      return true
    } else {
      XCTFail(
        "String expected to contain: \n" + ANSIColors.green("```\n\(pattern)\n```\n")
          + "but it was actually:\n" + ANSIColors.red("```\n\(res)\n```"),
        file: #file, line: #line)
      return false
    }
  } catch {
    print("Invalid regular expression: \(error.localizedDescription)")
    return false
  }
}

// /// Find html element by id
// /// - Parameters:
// ///   - id: css id of the element to be found
// ///   - html: string in which to search for the element
// /// - Returns: string representation of the element with the given id
// public func findByID(_ id: String, in html: String) -> String {
//   let doc = try! HTML(html: html, encoding: .utf8)
//   return doc.at_css("#\(id)")?.toHTML ?? ""
// }

// /// Find html elements by tag
// /// - Parameters:
// ///   - tag: html tag of the elements to be found
// ///   - html: string in which to search for the element
// /// - Returns: array of string representations of the elements with the given tag
// public func findByTag(_ tag: String, in html: String) -> [String] {
//   let doc = try! HTML(html: html, encoding: .utf8)
//   return doc.css(tag).map { $0.toHTML! }
// }

// /// Find html elements by class
// /// - Parameters:
// ///   - className: css class of the elements to be found
// ///   - html: string in which to search for the element
// /// - Returns: array of string representations of the elements with the given class
// public func findByClass(_ className: String, in html: String) -> [String] {
//   let doc = try! HTML(html: html, encoding: .utf8)
//   return doc.css(".\(className)").map { $0.toHTML! }
// }

public func assertPageTitle(_ pageTitle: String, in html: String, file: StaticString = #file, line: UInt = #line) {
  // assertContains(findByTag("h1", in: findByID("summary", in: html)).first, what: pageTitle, file: file, line: line)
  assertContains(html, what: "<h1>\(pageTitle)</h1>", file: file, line: line)
}

public func assertSummary(_ summary: String, in html: String, file: StaticString = #file, line: UInt = #line) {
  // assertContains(findByID("summary", in: html), what: summary, file: file, line: line)
  assertContains(html, what: summary, file: file, line: line)
}

public func assertDetails(_ details: String, in html: String, file: StaticString = #file, line: UInt = #line) {
  // assertContains(findByID("details", in: html), what: details, file: file, line: line)
  assertContains(html, what: details, file: file, line: line)
}

public func assertContent(_ content: String, in html: String, file: StaticString = #file, line: UInt = #line) {
  // assertContains(findByID("content", in: html), what: content, file: file, line: line)
  assertContains(html, what: content, file: file, line: line)
}

/// Assert that html contains an html element with the given id and has the same children (list items) count as the given count
/// - Parameters:
///   - id: css id of the element to be found
///   - count: number of children elements (list items) expected to be found
///   - html: string in which to search for the element
public func assertListExistAndCount(id: String, count: Int, in html: String, file: StaticString = #file, line: UInt = #line) {
  // let doc = findByID(id, in: html)
  // if doc.isEmpty {
  if !html.contains(id) {
    XCTFail(
      "\nExpected to find " + ANSIColors.green("\(id)\n")
        + "but found " + ANSIColors.red("nothing\n"),
      file: file, line: line)
    return
  }
  // let res: [String] = findByTag("li", in: doc)
  // let actualCount = res.count
  let actualCount = html.components(separatedBy:"<li id=\"\(id)Item\">").count - 1
  if actualCount != count {
    XCTFail(
      "\nExpected to find " + ANSIColors.green("\(count) \(id)\n")
        + "but found " + ANSIColors.red("\(actualCount)"),
      file: file, line: line)
    return
  }
}

/// Assert that html contains sections with the given titles and the given number of declarations
/// - Parameters:
///   - dict: dictionary with section titles as keys and number of declarations as values
///   - members: html string in which to search for the sections
public func assertSectionsExsistingAndCount(_ dict: [String: Int], in members: String, file: StaticString = #file, line: UInt = #line) {
  for (title, count) in dict {
    let id = convertToID(title) as! String
    if count > 0 {
      // let section = findByID(id, in: members)
      assertContains(members, what: "<h2>\(title)</h2>", file: file, line: line)

      // let declarationsCount = findByClass("declaration", in: section).count
      let declarationsCount = members.components(separatedBy:"<div class=\"declaration\" id=\"\(id)Item\">").count - 1
      if declarationsCount != count {
      XCTFail(
        "\nExpected to find " + ANSIColors.green("\(count) \(id)\n")
          + "but found " + ANSIColors.red("\(declarationsCount)"),
        file: file, line: line)
      return
    }
    }
    else {
      assertNotContains(members, what: id, file: file, line: line)
    }
  }
}