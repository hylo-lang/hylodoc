import MarkdownKit
import XCTest

@testable import DocExtractor

final class DealerTests: XCTestCase {
  func testIsEven() {
    // extractData()
    extractComments()
  }
}

final class MarkdownParsingTests: XCTestCase {
  func testProcessCommentLines_ValidInput() {
    let lines = [
      "/// First paragraph is the summary.",
      "///",
      "/// Markdown __formatting__ is *supported*.",
    ]

    do {
      let processed = try processCommentLines(lines)
      XCTAssertEqual(
        processed,
        [
          "First paragraph is the summary.",
          "",
          "Markdown __formatting__ is *supported*.",
        ])
    } catch {
      XCTFail("processCommentLines threw an unexpected error: \(error)")
    }
  }

  func testProcessCommentLines_LeadingWhitespaces() {
    let lines = [
      " /// First paragraph is the summary.",
      "  /// Markdown __formatting__ is *supported*.",
    ]

    do {
      let processed = try processCommentLines(lines)
      XCTAssertEqual(
        processed,
        [
          "First paragraph is the summary.",
          "Markdown __formatting__ is *supported*.",
        ])
    } catch {
      XCTFail("processCommentLines threw an unexpected error: \(error)")
    }
  }

  func testProcessCommentLines_invalidInput() {
    let lines = [
      "// First paragraph is the summary.",
      "// Markdown __formatting__ is *supported*.",
    ]

    XCTAssertThrowsError(try processCommentLines(lines))
  }

  func testParseMarkdown_ValidAPIInput() {
    let codeLines = [
      "/// First paragraph is the summary.",
      "///",
      "/// Markdown __formatting__ is *supported* in",
      "/// the description.",
      "///",
      "/// It can also be multiple paragraphs long.",
      "///",
      "/// # Parameters:",
      "/// - width: The width of the rectangle.",
      "/// - height: The height of the rectangle.",
      "///",
      "/// # Preconditions:",
      "/// - width \\< height – the rectangle should be",
      "/// longer vertically than horizontally",
      "/// - width and height must be positive",
      "///",
      "/// # Returns:",
      "/// - The calculated area if width is even",
      "/// - 0 otherwise",
    ]

    do {
      let apiresult = try parseMarkdown(from: codeLines)

      guard case .apiDoc = apiresult.type else {
        XCTFail("Not interpreted as Api Doc")
        return
      }

      let blocks = apiresult.content
      if !blocks.isEmpty {
        for block in blocks {
          print(block.debugDescription)
        }
      }
      for section in apiresult.specialSections {
        print(section.name)
        for block in section.blocks {
          print(block.debugDescription)
        }
      }
      XCTAssert(true)
    } catch {
      XCTFail("parseMarkdown threw an unexpected error: \(error)")
    }
  }

  func testParseMarkdown_InvalidAPIInputEmptyHeading() {
    let codeLines = [
      "/// First paragraph is the summary.",
      "///",
      "/// Markdown __formatting__ is *supported* in",
      "/// the description.",
      "///",
      "/// It can also be multiple paragraphs long.",
      "///",
      "/// #",
      "/// - width: The width of the rectangle.",
      "/// - height: The height of the rectangle.",
      "///",
      "/// # Preconditions:",
      "/// - width < height – the rectangle should be",
      "/// longer vertically than horizontally",
      "/// - width and height must be positive",
      "///",
      "/// # Returns:",
      "/// - The calculated area if width is even",
      "/// - 0 otherwise",
    ]

    XCTAssertThrowsError(try parseMarkdown(from: codeLines)) { error in
      if let markdownError = error as? MarkdownParserError {
        switch markdownError {
        case .improperStructure:
          XCTAssert(true)
        default:
          XCTFail("Unexpected MarkdownParserError")
        }
      } else {
        XCTFail("Unexpected error type. ")
      }
    }

  }

  func testParseMarkdown_ValidFileInput() {
    let codeLines = [
      "/// # File-level: ",
      "///",
      "/// Markdown __formatting__ is *supported* in",
      "/// the description.",
      "///",
      "/// It can also be multiple paragraphs long.",
      "///",
      "/// # See also:",
      "/// - width: The width of the rectangle.",
      "/// - height: The height of the rectangle.",
    ]

    do {
      let apiresult = try parseMarkdown(from: codeLines)

      guard case .fileDoc = apiresult.type else {
        XCTFail("Not interpreted as Api Doc")
        return
      }

      let blocks = apiresult.content

      if !blocks.isEmpty {
        XCTFail("File-level was not interpreted as a heading.")
      }
      for section in apiresult.specialSections {
        print(section.name)
        for block in section.blocks {
          print(block.debugDescription)
        }
      }
      XCTAssert(true)
    } catch {
      XCTFail("parseMarkdown threw an unexpected error: \(error)")
    }
  }
}
