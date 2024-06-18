import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringIsEmptyTest: XCTestCase {
  func testIsEmptyWithTagAndEmptyChildren() {
    let renderString: RenderString = .tag(.wrap, [])
    XCTAssertTrue(renderString.isEmpty())
  }

  func testIsEmptyWithTagAndNonEmptyChildren() {
    let renderString: RenderString = .tag(
      .wrap,
      [
        .text("Content")
      ])
    XCTAssertFalse(renderString.isEmpty())
  }

  func testIsEmptyWithText() {
    let renderString: RenderString = .text("Hello")
    XCTAssertFalse(renderString.isEmpty())
  }

  func testIsEmptyWithEmptyText() {
    let renderString: RenderString = .text("")
    XCTAssertTrue(renderString.isEmpty())
  }

  func testIsEmptyWithIndentation() {
    let renderString: RenderString = .indentation(2)
    XCTAssertFalse(renderString.isEmpty())
  }

  func testIsEmptyWithZeroIndentation() {
    let renderString: RenderString = .indentation(0)
    XCTAssertTrue(renderString.isEmpty())
  }

  func testIsEmptyWithOtherCases() {
    let renderString: RenderString = .escape(.lessThan)
    XCTAssertFalse(renderString.isEmpty())
  }
}
