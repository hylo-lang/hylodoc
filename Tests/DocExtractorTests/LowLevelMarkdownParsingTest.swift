import MarkdownKit
import XCTest

@testable import DocExtractor

final class LowLevelMarkdownParsingTests: XCTestCase {
  func testStripLeadingDocSlashes_ValidInput() {
    let parser = RealLowLevelCommentParser()

    let processed = parser.stripLeadingDocSlashes(commentLines: [
      "/// First paragraph is the summary.",
      "///",
      "/// Markdown __formatting__ is *supported*.",
    ])

    let res = try? processed.get()
    XCTAssertNotNil(res)

    XCTAssertEqual(
      res!,
      [
        "First paragraph is the summary.",
        "",
        "Markdown __formatting__ is *supported*.",
      ]
    )

  }

  func testStripLeadingDocSlashes_LeadingWhitespacesAreStripped() {
    let parser = RealLowLevelCommentParser()

    let processed = parser.stripLeadingDocSlashes(commentLines: [
      " /// First paragraph is the summary.",
      "  /// Markdown __formatting__ is *supported*.",
    ])

    switch processed {
      case .success(let result):
        XCTAssertEqual(
          result,
          [
            "First paragraph is the summary.",
            "Markdown __formatting__ is *supported*.",
          ]
        )
      case .failure(let error):
        XCTFail("unexpected error: \(error)")
    }
  }


  func testStripLeadingDocSlashes_OnlyFirstWhitespaceAfterSlashesIsStripped() {
    let parser = RealLowLevelCommentParser()

    let processed = parser.stripLeadingDocSlashes(commentLines: [
      "/// First paragraph is the summary.",
      "///     void main();",
    ])

    switch processed {
      case .success(let result):
        XCTAssertEqual(
          result,
          [
            "First paragraph is the summary.",
            "    void main();",
          ]
        )
      case .failure(let error):
        XCTFail("unexpected error: \(error)")
    }
  }

  func testProcessCommentLines_invalidInputWithoutOneSpaceAfterSlashes() {
    let parser = RealLowLevelCommentParser()

    let processed = parser.stripLeadingDocSlashes(commentLines: [
      "/// First paragraph is the summary.",
      "///Markdown __formatting__ is *supported*.",
    ])

    switch processed {
      case .success:
        XCTFail("Expected an error, but got success.")
      case .failure(let error):
        XCTAssertEqual(error, .missingWhitespace(inLine: "///Markdown __formatting__ is *supported*."))
    }
  }

  func testParseMarkdown_ValidAPIInput() {
    let parser = RealLowLevelCommentParser()

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
      "/// - width \\< height - the rectangle should be",
      "/// longer vertically than horizontally",
      "/// - width and height must be positive",
      "///",
      "/// # Returns:",
      "/// - The calculated area if width is even",
      "/// - 0 otherwise",
    ]

    let result = parser.parse(commentLines: codeLines)

    switch result {
      case .success(let parsed):
        XCTAssertEqual(parsed.type, .symbol)
        XCTAssertEqual(parsed.contentBeforeSections.count, 3)
        XCTAssertEqual(parsed.specialSections.count, 3)

        let firstSection = parsed.specialSections[0]
        XCTAssertEqual(firstSection.name, "Parameters:")
        assertContains(firstSection.blocks.description, what: "width: The width of the rectangle.")
        assertContains(firstSection.blocks.description, what: "height: The height of the rectangle.")

        let secondSection = parsed.specialSections[1]
        XCTAssertEqual(secondSection.name, "Preconditions:")
        assertContains(secondSection.blocks.description, what: "width < height - the rectangle should be")
        assertContains(secondSection.blocks.description, what: "longer vertically than horizontally")
        assertContains(secondSection.blocks.description, what: "width and height must be positive")

        let thirdSection = parsed.specialSections[2]
        XCTAssertEqual(thirdSection.name, "Returns:")
        XCTAssertTrue(thirdSection.blocks.description.contains("The calculated area if width is even"))
        XCTAssertTrue(thirdSection.blocks.description.contains("0 otherwise"))

      case .failure(let error):
        XCTFail("Unexpected error: \(error)")
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

    let parser = RealLowLevelCommentParser()
    let result = parser.parse(commentLines: codeLines)
    
    switch result {
      case .success(let value):
        XCTFail("Expected an error, but got success. Parsed as:\(value)")
      case .failure(let error):
        XCTAssertEqual(error, .emptySpecialSectionHeading)
    }
  }

  func testParseMarkdown_ValidFileLevelInput() {
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

    let parser = RealLowLevelCommentParser()
    let result = parser.parse(commentLines: codeLines)

    switch result {
      case .success(let parsed):
        XCTAssertEqual(parsed.type, .fileLevel)
        XCTAssertEqual(parsed.contentBeforeSections.count, 0)
        XCTAssertEqual(parsed.specialSections.count, 2)

        let fileLevelSection = parsed.specialSections[0]
        XCTAssertEqual(fileLevelSection.name, "File-level:")
      
        assertContains(fileLevelSection.blocks.description, what: "in")
        assertContains(fileLevelSection.blocks.description, what: "the description.")
        assertContains(fileLevelSection.blocks.description, what: "It can also be multiple paragraphs long.")

        let seeAlsoSection = parsed.specialSections[1]
        XCTAssertEqual(seeAlsoSection.name, "See also:")
        assertContains(seeAlsoSection.blocks.description, what: "width: The width of the rectangle.")
        assertContains(seeAlsoSection.blocks.description, what: "height: The height of the rectangle.")

      case .failure(let error):
        XCTFail("Unexpected error: \(error)")
    }
  }
}