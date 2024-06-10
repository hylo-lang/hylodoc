import OrderedCollections
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class TableOfContentsHelperTest: XCTestCase {
  func testBasedOnKeyPrecense() {
    var env: [String: Any] = [:]
    env["details"] = "Info"
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [
        tocItem(id: "details", name: "Details", children: []),
        tocItem(id: "content", name: "Content", children: []),
      ]
    )
  }

  func testBasedOnKeyAbsence() {
    var env: [String: Any] = [:]
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [tocItem(id: "content", name: "Content", children: [])]
    )
  }

  func testBasedOnEmptyValueString() {
    var env: [String: Any] = [:]
    env["details"] = ""
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [tocItem(id: "content", name: "Content", children: [])]
    )
  }

  func testBasedOnEmptyValueArray() {
    var env: [String: Any] = [:]
    env["details"] = []
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [tocItem(id: "content", name: "Content", children: [])]
    )
  }

  func testBasedOnEmptyValueDictionary() {
    var env: [String: Any] = [:]
    env["details"] = [:]
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [tocItem(id: "content", name: "Content", children: [])]
    )
  }

  func testEmptyMembers() {
    var env: [String: Any] = [:]
    env["members"] = []
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [tocItem(id: "content", name: "Content", children: [])]
    )
  }

  func testNonEmptyMembers() {
    var env: [String: Any] = [:]

    // the order of the buckets is what determines the order of the sections in the page
    var buckets: OrderedDictionary<String, nameAndContentArray> = [
      "Associated Types": [],
      "Associated Values": [],
      "Type Aliases": [],
      "Bindings": [],
      "Operators": [],
      "Functions": [],
      "Methods": [],
      "Method Implementations": [],
      "Subscripts": [],
      "Subscript Implementations": [],
      "Initializers": [],
      "Traits": [],
      "Product Types": [],
    ]
    buckets["Traits", default: []].append((name: "John", summary: "Doe"))
    buckets["Method Implementations", default: []].append((name: "John", summary: "Doe"))

    env["members"] = buckets.filter { !$0.value.isEmpty }.map { $0 }
    env["content"] = "Some other stuff"

    XCTAssertEqual(
      tableOfContents(stencilContext: env),
      [
        tocItem(id: "content", name: "Content", children: []),
        tocItem(
          id: "members", name: "Members",
          children: [
            tocItem(id: "methodImplementations", name: "Method Implementations", children: []),
            tocItem(id: "traits", name: "Traits", children: []),
          ]),
      ]
    )
  }
}
