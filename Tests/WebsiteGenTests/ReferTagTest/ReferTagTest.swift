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

  func testCorrectInputs() throws {
    try XCTAssertEqual(
      try render(
        "{% refer a b %}",
        [
          "a": RelativePath(pathString: "some/path/file.html"),
          "b": RelativePath(pathString: "some/path/article.html"),
        ]
      ),
      "article.html"
    )
  }

  func testIncorrectFrom() {
    XCTAssertThrowsError(
      try render(
        "{% refer a b %}",
        [
          "a": "/my/path/index.html",
          "b": RelativePath(pathString: "some/path/folder/file.html"),
        ]
      ),
      "some/path/folder/file.html"
    )
  }

  func testIncorrectTo() {
    XCTAssertThrowsError(
      try render(
        "{% refer a b %}",
        [
          "a": RelativePath(pathString: "some/path/folder/file.html"),
          "b": "/my/path/index.html",
        ]
      ),
      "."
    )
  }

  func testBothIncorrect() {
    XCTAssertThrowsError(
      try render(
        "{% refer a b %}",
        [
          "a": "/my/path/index.html",
          "b": "oh/no/anyway.html",
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
