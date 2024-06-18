import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringLengthTest: XCTestCase {
  func testLengthText() {
    let renderString: RenderString = .text("Hello, world!")
    XCTAssertEqual(renderString.length(), 13)
  }

  func testLengthEscape() {
    let renderString: RenderString = .escape(.lessThan)
    XCTAssertEqual(renderString.length(), 1)
  }

  func testLengthIndentation() {
    let renderString: RenderString = .indentation(4)
    XCTAssertEqual(renderString.length(), 4)
  }

  func testLengthTagWithChildren() {
    let children: [RenderString] = [
      .text("This is "),
      .tag(.keyword, [.text("important")]),
      .text("!"),
    ]
    let renderString: RenderString = .tag(.wrap, children)

    XCTAssertEqual(renderString.length(), 18)  // Total length of "This is important!"
  }

  func testLengthTagWithoutChildren() {
    let renderString: RenderString = .tag(.keyword, [])
    XCTAssertEqual(renderString.length(), 0)
  }

  func testLengthNestedTags() {
    let innerChildren: [RenderString] = [
      .text("nested "),
      .tag(.name, [.text("tags")]),
    ]
    let outerChildren: [RenderString] = [
      .text("Outer "),
      .tag(.type(nil), innerChildren),
      .text(" with "),
      .tag(.keyword, [.text("multiple")]),
      .text(" children"),
    ]
    let renderString: RenderString = .tag(.wrap, outerChildren)

    XCTAssertEqual(renderString.length(), 40)  // Total length of "Outer nested tags with multiple children"
  }

  func testLengthEdgeCases() {
    // Empty RenderString
    let emptyString: RenderString = .tag(.wrap, [])
    XCTAssertEqual(emptyString.length(), 0)

    // RenderString with multiple indentations
    let indentedString: RenderString = .tag(
      .wrap,
      [
        .indentation(2),
        .text("Indented "),
        .indentation(3),
        .text("text"),
        .indentation(1),
      ])
    XCTAssertEqual(indentedString.length(), 19)  // Total length of "  Indented    text "

    // RenderString with mixed content types
    let mixedContent: RenderString = .tag(
      .wrap,
      [
        .text("Mixed "),
        .tag(.type(nil), [.text("content")]),
        .escape(.lessThan),
        .text(" & "),
        .indentation(2),
        .tag(.keyword, [.text("tags")]),
      ])
    XCTAssertEqual(mixedContent.length(), 23)  // Total length of "Mixed content< &   tags"
  }
}
