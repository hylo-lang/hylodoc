import DocExtractor
@testable import FrontEnd
import MarkdownKit
import TestUtils
import XCTest
import DocumentationDB

@testable import WebsiteGen

final class LinkAndImageRenderingTests: XCTestCase {
  func setupDummyContext() throws -> ReferenceRenderingContext {
    .init(
      typedProgram: try checkNoDiagnostic{ d in try TypedProgram(annotating: ScopedProgram(AST()), reportingDiagnosticsTo: &d) },
      scopeId: AnyScopeID(ProductTypeDecl.ID(rawValue: 0)),
      resolveUrls: { _ in nil },
      sourceUrl: URL(fileURLWithPath: "/"),
      assetStore: AssetStore()
    )
  }
  func testUrlLinkRendering() throws{
    let generator = CustomHTMLGenerator()
    generator.referenceContext = try setupDummyContext()

    XCTAssertEqual(
      generator.generate(textFragment: .link(Text("text"), "https://URL", "TITLE")),
      "<a href=\"https://URL\" title=\"TITLE\">text</a>"
    )

    XCTAssertEqual(
      generator.generate(textFragment: .link(Text("text"), nil, "TITLE")),
      "text"
    )

    XCTAssertEqual(
      generator.generate(textFragment: .link(Text("text"), "https://URL", nil)),
      "<a href=\"https://URL\">text</a>"
    )

    XCTAssertEqual(
      generator.generate(textFragment: .link(Text(""), "https://URL", "TITLE")),
      "<a href=\"https://URL\" title=\"TITLE\"></a>"
    )
  }

  func testLinkRenderingForEmails() throws {
    let generator = CustomHTMLGenerator()
    generator.referenceContext = try setupDummyContext()
    
    XCTAssertEqual(
      generator.generate(textFragment: .link(Text("text"), "mailto:a@b.com", nil)),
      "<a href=\"mailto:a@b.com\">text</a>"
    )
  }

  let hylodocMDParser = HyloDocMarkdownParser.standard

  func testUrlLinkParsing() {
    // empty link
    XCTAssertEqual(
      hylodocMDParser.parse("[]()"),
      .document([
        .paragraph(
          Text(
            .link(.init(), nil, nil)
          )
        )
      ])
    )

    // link with text
    XCTAssertEqual(
      hylodocMDParser.parse("[text]()"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), nil, nil)
          )
        )
      ])
    )

    // link with url
    XCTAssertEqual(
      hylodocMDParser.parse("[](https://url)"),
      .document([
        .paragraph(
          Text(
            .link(.init(), "https://url", nil)
          )
        )
      ])
    )

    // link with text and url
    XCTAssertEqual(
      hylodocMDParser.parse("[text](https://url)"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), "https://url", nil)
          )
        )
      ])
    )

    // link with text and url and title
    XCTAssertEqual(
      hylodocMDParser.parse("[text](https://url \"title\")"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), "https://url", "title")
          )
        )
      ])
    )
  }

  func testLinkWithRelativePath() {
    // link with not http url
    XCTAssertEqual(
      hylodocMDParser.parse("[text](url)"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), "url", nil)
          )
        )
      ])
    )

    // link with relative path
    XCTAssertEqual(
      hylodocMDParser.parse("[text](./path)"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), "./path", nil)
          )
        )
      ])
    )

    // link with complex relative path
    XCTAssertEqual(
      hylodocMDParser.parse("[text](./path/../to/file)"),
      .document([
        .paragraph(
          Text(
            .link(Text("text"), "./path/../to/file", nil)
          )
        )
      ])
    )
  }

  func testAutoLink() {
    // https url
    XCTAssertEqual(
      hylodocMDParser.parse("<https://google.com>"),
      .document([
        .paragraph(
          Text(
            .autolink(.uri, "https://google.com")
          )
        )
      ])
    )

    // email with mailto protocol should get parsed into a url
    XCTAssertEqual(
      hylodocMDParser.parse("<mailto:a@b.com>"),
      .document([
        .paragraph(
          Text(
            .autolink(.uri, "mailto:a@b.com")
          )
        )
      ])
    )

    // standalone email should get parsed into an email
    XCTAssertEqual(
      hylodocMDParser.parse("<a@b.com>"),
      .document([
        .paragraph(
          Text(
            .autolink(.email, "a@b.com")
          )
        )
      ])
    )

    // relative urls don't work as autolinks
    XCTAssertNotEqual(
      hylodocMDParser.parse("<./hello/>"),
      .document([
        .paragraph(
          Text(
            .autolink(.uri, "./hello/")
          )
        )
      ])
    )
  }

  func testResolutionOfLocalFiles() throws {
    // Testing that all local file references are resolved. 
    // If something wouldnt resolve, it would cause a fatal error.
    // It's not ideal, but we would need to introduce exceptions all the way to make this work,
    // which would be a bit of refactoring.
    try runFullPipelineWithoutErrors(
      at: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("TestModule", isDirectory: true))

    // todo assert the number of links generated in the output.
  }
}
