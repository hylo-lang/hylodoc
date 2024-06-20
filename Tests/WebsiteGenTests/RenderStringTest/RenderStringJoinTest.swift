import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringJoinTest: XCTestCase {
  func testJoinWithRenderStringSeparator() {
    let elements: [RenderString] = [
      .text("Item 1"),
      .text("Item 2"),
      .text("Item 3"),
    ]

    let joined = RenderString.join(elements, .text("; "))

    let expected = RenderString.wrap([
      .text("Item 1"),
      .text("; "),
      .text("Item 2"),
      .text("; "),
      .text("Item 3"),
    ])

    XCTAssertEqual(joined, expected)
  }

  func testJoinWithStringSeparator() {
    let elements: [RenderString] = [
      .text("Apple"),
      .text("Orange"),
      .text("Banana"),
    ]

    let joined = RenderString.join(elements)

    let expected = RenderString.wrap([
      .text("Apple"),
      .text(", "),
      .text("Orange"),
      .text(", "),
      .text("Banana"),
    ])

    XCTAssertEqual(joined, expected)
  }

  func testAppendRenderString() {
    var renderString: RenderString = .tag(
      .wrap,
      [
        .text("Initial ")
      ])

    let appended: RenderString = .text("content")

    renderString += appended

    let expected: RenderString = .tag(
      .wrap,
      [
        .text("Initial "),
        .text("content"),
      ])

    XCTAssertEqual(renderString, expected)
  }

  func testAppendString() {
    var renderString: RenderString = .tag(
      .wrap,
      [
        .text("Initial ")
      ])

    let appended: String = "text"

    renderString += appended

    let expected: RenderString = .tag(
      .wrap,
      [
        .text("Initial "),
        .text("text"),
      ])

    XCTAssertEqual(renderString, expected)
  }
}
