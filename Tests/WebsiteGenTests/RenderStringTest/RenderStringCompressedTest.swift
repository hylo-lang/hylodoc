import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringCompressedTest: XCTestCase {
  func testTextEquality() {
    let string1 = RenderString.text("Hello, world!")
    let string2 = RenderString.text("Hello, world!")
    XCTAssertEqual(string1, string2)
  }

  func testTextInequality() {
    let string1 = RenderString.text("Hello, world!")
    let string2 = RenderString.text("Goodbye, world!")
    XCTAssertNotEqual(string1, string2)
  }

  func testEscapeEquality() {
    let string1 = RenderString.escape(.lessThan)
    let string2 = RenderString.escape(.lessThan)
    XCTAssertEqual(string1, string2)
  }

  func testEscapeInequality() {
    let string1 = RenderString.escape(.lessThan)
    let string2 = RenderString.escape(.greaterThan)
    XCTAssertNotEqual(string1, string2)
  }

  func testIndentationEquality() {
    let string1 = RenderString.indentation(4)
    let string2 = RenderString.indentation(4)
    XCTAssertEqual(string1, string2)
  }

  func testIndentationInequality() {
    let string1 = RenderString.indentation(4)
    let string2 = RenderString.indentation(2)
    XCTAssertNotEqual(string1, string2)
  }

  func testTagEquality() {
    let string1 = RenderString.tag(.keyword, [RenderString.text("if")])
    let string2 = RenderString.tag(.keyword, [RenderString.text("if")])
    XCTAssertEqual(string1, string2)
  }

  func testTagInequalityDifferentNames() {
    let string1 = RenderString.tag(.keyword, [RenderString.text("if")])
    let string2 = RenderString.tag(.name, [RenderString.text("if")])
    XCTAssertNotEqual(string1, string2)
  }

  func testTagInequalityDifferentChildren() {
    let string1 = RenderString.tag(.keyword, [RenderString.text("if")])
    let string2 = RenderString.tag(.keyword, [RenderString.text("else")])
    XCTAssertNotEqual(string1, string2)
  }

  func testCompressedCombinesConsecutiveTexts() {
    let string = RenderString.tag(
      .wrap,
      [
        .text("Hello"),
        .text(", "),
        .text("world"),
        .text("!"),
      ])
    let expected = RenderString.text("Hello, world!")
    XCTAssertEqual(string, expected)
  }

  func testCompressedRemovesEmptyChildren() {
    let string = RenderString.tag(
      .wrap,
      [
        .text("Hello"),
        .text(""),
        .text(", world!"),
      ])
    let expected = RenderString.text("Hello, world!")
    XCTAssertEqual(string, expected)
  }

  func testCombineThreeIndentations() {
    let string = RenderString.tag(
      .wrap,
      [
        .indentation(1),
        .indentation(2),
        .indentation(3),
        .text("Hello, world!"),
      ])
    let expected = RenderString.tag(
      .wrap,
      [
        .indentation(6),
        .text("Hello, world!"),
      ])
    XCTAssertEqual(string, expected)
  }

  func testNonConsecutiveIndentations() {
    let string = RenderString.tag(
      .wrap,
      [
        .indentation(2),
        .text("Hello"),
        .indentation(3),
        .indentation(1),
        .text("world!"),
      ])
    let expected = RenderString.tag(
      .wrap,
      [
        .indentation(2),
        .text("Hello"),
        .indentation(4),
        .text("world!"),
      ])
    XCTAssertEqual(string, expected)
  }

  func testCompressedHandlesNestedEmptyStuff() {
    let emptyTag = RenderString.wrap()
    let string = RenderString.wrap(
      [
        emptyTag,
        .wrap(
          [
            emptyTag,
            .text("Hello"),
            emptyTag,
            .text(", "),
            .text("world!"),
            emptyTag,
          ]),
        emptyTag,
      ])
    let expected = RenderString.text("Hello, world!")
    XCTAssertEqual(string, expected)
  }

  func testEmptyText() {
    let string = RenderString.wrap(
      [
        .text(""),
        .text(""),
        .text(""),
      ])
    let expected = RenderString.wrap()
    XCTAssertEqual(string, expected)
  }

  func testComplexCombinedFeatures() {
    let string = RenderString.wrap(
      [
        .indentation(2),
        .type(
          [
            .text("Complex "),
            .keyword(
              [
                .text("test"),
                .text(" "),
                .text("case"),
              ]),
            .text(" for "),
            .link(
              [
                .text("combined"),
                .text(" "),
                .text("features"),
              ], href: "https://example.com"),
            .text(":"),
            .escape(.lessThan),
            .text("escaped "),
            .escape(.greaterThan),
            .indentation(3),
            .text("Hello,"),
            .indentation(1),
            .indentation(1),
            .text("world!"),
            .indentation(0),
          ], href: nil),
        .indentation(1),
        .text("End of complex test"),
        .indentation(0),
      ])

    let expected = RenderString.wrap(
      [
        .indentation(2),
        .type(
          [
            .text("Complex "),
            .keyword(
              [
                .text("test case")
              ]),
            .text(" for "),
            .link(
              [
                .text("combined features")
              ], href: "https://example.com"),
            .text(":"),
            .escape(.lessThan),
            .text("escaped "),
            .escape(.greaterThan),
            .indentation(3),
            .text("Hello,"),
            .indentation(2),
            .text("world!"),
          ], href: nil),
        .indentation(1),
        .text("End of complex test"),
      ])

    XCTAssertEqual(string, expected)
  }
}
