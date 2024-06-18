import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import WebsiteGen

final class RenderStringToHTMLTest: XCTestCase {
  func testToHTMLText() {
    let renderString: RenderString = .text("Hello, world!")
    XCTAssertEqual(renderString.toHTML(), "Hello, world!")
  }

  func testToHTMLEscape() {
    let renderString: RenderString = .escape(.lessThan)
    XCTAssertEqual(renderString.toHTML(), "&lt;")
  }

  func testToHTMLIndentation() {
    let renderString: RenderString = .indentation(4)
    XCTAssertEqual(renderString.toHTML(), "<span class=\"indentation\">    </span>")
  }

  func testToHTMLTagWithChildren() {
    let renderString: RenderString = .wrap([
      .text("This is "),
      .tag(.keyword, [.text("important")]),
      .text("!"),
    ])

    let expected = "This is <span class=\"keyword\">important</span>!"
    XCTAssertEqual(renderString.toHTML(), expected)
  }

  func testToHTMLTagWithoutChildren() {
    let renderString: RenderString = .tag(.keyword, [])
    XCTAssertEqual(renderString.toHTML(), "")
  }
}
