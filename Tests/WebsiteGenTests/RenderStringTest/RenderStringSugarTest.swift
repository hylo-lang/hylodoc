import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringSugarTest: XCTestCase {
  func testTagWithNameAndText() {
    let tag = RenderString.tag(.keyword, "test")
    let expected = RenderString.tag(.keyword, [.text("test")])
    XCTAssertEqual(tag, expected)
  }

  func testWrapWithChildren() {
    let children: [RenderString] = [.text("Hello"), .text(", world!")]
    let wrapped = RenderString.wrap(children)
    let expected = RenderString.tag(.wrap, children)
    XCTAssertEqual(wrapped, expected)
  }

  func testWrapWithText() {
    let wrapped = RenderString.wrap("Hello, world!")
    let expected = RenderString.tag(.wrap, [.text("Hello, world!")])
    XCTAssertEqual(wrapped, expected)
  }

  func testKeywordWithChildren() {
    let children: [RenderString] = [.text("Hello"), .text(", world!")]
    let keyword = RenderString.keyword(children)
    let expected = RenderString.tag(.keyword, children)
    XCTAssertEqual(keyword, expected)
  }

  func testKeywordWithText() {
    let keyword = RenderString.keyword("Hello, world!")
    let expected = RenderString.tag(.keyword, [.text("Hello, world!")])
    XCTAssertEqual(keyword, expected)
  }

  func testNameWithChildren() {
    let children: [RenderString] = [.text("Hello"), .text(", world!")]
    let name = RenderString.name(children)
    let expected = RenderString.tag(.name, children)
    XCTAssertEqual(name, expected)
  }

  func testNameWithText() {
    let name = RenderString.name("Hello, world!")
    let expected = RenderString.tag(.name, [.text("Hello, world!")])
    XCTAssertEqual(name, expected)
  }

  func testNumberWithChildren() {
    let children: [RenderString] = [.text("123"), .text(".45")]
    let number = RenderString.number(children)
    let expected = RenderString.tag(.number, children)
    XCTAssertEqual(number, expected)
  }

  func testNumberWithText() {
    let number = RenderString.number("123.45")
    let expected = RenderString.tag(.number, [.text("123.45")])
    XCTAssertEqual(number, expected)
  }

  func testLinkWithChildren() {
    let children: [RenderString] = [.text("Click "), .text("here")]
    let link = RenderString.link(children, href: "https://example.com")
    let expected = RenderString.tag(.link("https://example.com"), children)
    XCTAssertEqual(link, expected)
  }

  func testLinkWithText() {
    let link = RenderString.link("Click here", href: "https://example.com")
    let expected = RenderString.tag(.link("https://example.com"), [.text("Click here")])
    XCTAssertEqual(link, expected)
  }

  func testTypeWithChildren() {
    let children: [RenderString] = [.text("Swift"), .text(" code")]
    let type = RenderString.type(children, href: "https://swift.org")
    let expected = RenderString.tag(.type("https://swift.org"), children)
    XCTAssertEqual(type, expected)
  }

  func testTypeWithText() {
    let type = RenderString.type("Swift code", href: "https://swift.org")
    let expected = RenderString.tag(.type("https://swift.org"), [.text("Swift code")])
    XCTAssertEqual(type, expected)
  }
}
