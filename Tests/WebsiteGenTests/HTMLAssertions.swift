import DocumentationDB
import HyloStandardLibrary
import Kanna
import MarkdownKit
import Stencil
import TestUtils
import WebsiteGen
import XCTest

public func assertPageTitle(
  _ pageTitle: String, in html: String, file: StaticString = #file, line: UInt = #line
) {
  assertContains(
    findByTag("h1", in: findByID("summary", in: html)).first, what: pageTitle, file: file,
    line: line)
}

public func assertSummary(
  _ summary: String, in html: String, file: StaticString = #file, line: UInt = #line
) {
  assertContains(findByID("summary", in: html), what: summary, file: file, line: line)
}

public func assertDetails(
  _ details: String, in html: String, file: StaticString = #file, line: UInt = #line
) {
  assertContains(findByID("details", in: html), what: details, file: file, line: line)
}

public func assertContent(
  _ content: String, in html: String, file: StaticString = #file, line: UInt = #line
) {
  assertContains(findByID("content", in: html), what: content, file: file, line: line)
}

public func assertByID(
  _ id: String, contains: String, in html: String, file: StaticString = #file, line: UInt = #line
) {
  assertContains(findByID(id, in: html), what: contains, file: file, line: line)
}

/// Assert that html contains an html element with the given id and has the same children (list items) count as the given count
/// - Parameters:
///   - id: css id of the element to be found
///   - count: number of children elements (list items) expected to be found
///   - html: string in which to search for the element
/// Note: this function relies on the existence of <li> tags, therefore it won't work properly if `count == 1` and `id` is one of the following:
/// `complexityInfo`, `projectsInfo`, `returns`, `throwsInfo`, `yields`
/// Instead, use assertByID for these cases
public func assertListExistAndCount(
  id: String, count: Int, in html: String, file: StaticString = #file, line: UInt = #line
) {
  let doc = findByID(id, in: html)
  if doc.isEmpty {
    XCTFail(
      "\nExpected to find " + ANSIColors.green("\(id)\n")
        + "but found " + ANSIColors.red("nothing\n"),
      file: file, line: line)
    return
  }
  let res: [String] = findByTag("li", in: doc)
  let actualCount = res.count
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
public func assertSectionsExsistingAndCount(
  _ dict: [String: Int], in members: String, file: StaticString = #file, line: UInt = #line
) {
  for (title, count) in dict {
    let id = convertToID(title) as! String
    if count > 0 {
      let section = findByID(id, in: members)
      assertContains(members, what: "<h2>\(title)</h2>", file: file, line: line)

      let declarationsCount = findByClass("declaration", in: section).count
      if declarationsCount != count {
        XCTFail(
          "\nExpected to find " + ANSIColors.green("\(count) \(id)\n")
            + "but found " + ANSIColors.red("\(declarationsCount)"),
          file: file, line: line)
        return
      }
    } else {
      assertNotContains(members, what: id, file: file, line: line)
    }
  }
}


/// Helper functions for finding html elements

/// Find html element by id
/// - Parameters:
///   - id: css id of the element to be found
///   - html: string in which to search for the element
/// - Returns: string representation of the element with the given id
public func findByID(_ id: String, in html: String) -> String {
  let doc = try! HTML(html: html, encoding: .utf8)
  return doc.at_css("#\(id)")?.toHTML ?? ""
}

/// Find html elements by tag
/// - Parameters:
///   - tag: html tag of the elements to be found
///   - html: string in which to search for the element
/// - Returns: array of string representations of the elements with the given tag
public func findByTag(_ tag: String, in html: String) -> [String] {
  let doc = try! HTML(html: html, encoding: .utf8)
  return doc.css(tag).map { $0.toHTML! }
}

/// Find html elements by class
/// - Parameters:
///   - className: css class of the elements to be found
///   - html: string in which to search for the element
/// - Returns: array of string representations of the elements with the given class
public func findByClass(_ className: String, in html: String) -> [String] {
  let doc = try! HTML(html: html, encoding: .utf8)
  return doc.css(".\(className)").map { $0.toHTML! }
}
