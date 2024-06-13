import PathWrangler
import Stencil
import XCTest

@testable import WebsiteGen

final class ReferTagTest: XCTestCase {
  func testIncorrectFormatNoArguments() {
    XCTAssertThrowsError(try render("{% refer %}", [:]))
  }

  func testIncorrectFormatSingleArgument() {
    XCTAssertThrowsError(try render("{% refer a %}", [:]))
  }

  func testIncorrectFormatMultipleArgument() {
    XCTAssertThrowsError(try render("{% refer a b c %}", [:]))
  }

  func testSimpleStringString() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": "some/path/file.html",
          "b": "some/path/article.html",
        ]
      ),
      "article.html"
    )
  }

  func testSimpleRelativePathRelativePath() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": RelativePath(pathString: "some/path/file.html"),
          "b": RelativePath(pathString: "some/path/article.html"),
        ]
      ),
      "article.html"
    )
  }

  func testMixedStringRelativePath() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": "some/path/to/file.html",
          "b": RelativePath(pathString: "some/path/folder/file.html"),
        ]
      ),
      "../folder/file.html"
    )
  }

  func testUnsupportedFrom() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": 42,
          "b": RelativePath(pathString: "some/path/folder/file.html"),
        ]
      ),
      "some/path/folder/file.html"
    )
  }

  func testUnsupportedTo() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": RelativePath(pathString: "some/path/folder/file.html"),
          "b": 42,
        ]
      ),
      "."
    )
  }

  func testBothUnsupported() {
    XCTAssertEqual(
      try! render(
        "{% refer a b %}",
        [
          "a": 42,
          "b": 42,
        ]
      ),
      "."
    )
  }
}

private func render(_ template: String, _ context: [String: Any]) throws -> String {
  let ext = Extension()
  ext.registerTag("refer", parser: ReferNode.parse)

  let loader = DictionaryLoader(templates: ["test": template])
  var env = Environment(
    loader: loader,
    extensions: [ext],
    trimBehaviour: .smart
  )

  return try env.renderTemplate(name: "test", context: context)
}
