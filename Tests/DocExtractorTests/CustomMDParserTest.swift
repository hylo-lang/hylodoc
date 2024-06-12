import XCTest

@testable import DocExtractor
@testable import MarkdownKit

public final class CustomMDParserTest: XCTestCase {

  static let delimiterParser = HyloDocMarkdownParser(
    blockParsers: nil,
    inlineTransformers: [
      DelimiterTransformer.self
    ])

  static let hylodocMDParser = HyloDocMarkdownParser.standard

  func testDelimiterParserWorksForMultipleBackticks() {
    XCTAssertEqual(
      Self.delimiterParser.parse("`simple code`"),
      .document([
        .paragraph(
          Text([
            .delimiter("`", 1, []),
            .text("simple code"),
            .delimiter("`", 1, []),
          ]))
      ])
    )

    XCTAssertEqual(
      Self.delimiterParser.parse("``simple code``"),
      .document([
        .paragraph(
          Text([
            .delimiter("`", 2, []),
            .text("simple code"),
            .delimiter("`", 2, []),
          ]))
      ])
    )

    XCTAssertEqual(
      Self.delimiterParser.parse("``simple`` `code`"),
      .document([
        .paragraph(
          Text([
            .delimiter("`", 2, []),
            .text("simple"),
            .delimiter("`", 2, []),
            .text(" "),
            .delimiter("`", 1, []),
            .text("code"),
            .delimiter("`", 1, []),
          ]))
      ])
    )

    XCTAssertEqual(
      Self.delimiterParser.parse("<simple>"),
      .document([
        .paragraph(
          Text([
            .delimiter("<", 1, []),
            .text("simple"),
            .delimiter(">", 1, []),
          ]))
      ])
    )

    XCTAssertEqual(
      Self.delimiterParser.parse("<https://google.com>"),
      .document([
        .paragraph(
          Text([
            .delimiter("<", 1, []),
            .text("https://google.com"),
            .delimiter(">", 1, []),
          ]))
      ])
    )
  }

  func testNormalInlineCodeWorks() {
    XCTAssertEqual(
      Self.hylodocMDParser.parse("`simple code`"),
      .document([
        .paragraph(
          Text([
            .code("simple code")
          ]))
      ]),
      "Single backticks should be parsed as inline code"
    )

    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("```simple code```"),
      .document([
        .paragraph(
          Text([
            .code("simple code")
          ]))
      ]),
      "2+ backticks should be parsed as inline code"
    )

    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("````simple code````"),
      .document([
        .paragraph(
          Text([
            .code("simple code")
          ]))
      ]),
      "2+ backticks should be parsed as inline code"
    )
  }

  class DummyCustomHTMLRenderer: HtmlGenerator, HyloReferenceRenderer {
    /// Rendering hylo references by resolving the reference to a link to the actual target.
    func render(hyloReference reference: HyloReference) -> String {
      return "BEGIN\(reference.rawDescription)END"
    }
  }

  func testHyloCodeReferences() {
    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("``simple code``"),
      .document([
        .paragraph(
          Text([
            .custom(HyloReference("simple code"))
          ]))
      ]),
      "Double backticks should be parsed as Hylo references"
    )

    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("`` `simple code` ``"),
      .document([
        .paragraph(
          Text([
            .custom(HyloReference(" `simple code` "))
          ]))
      ]),
      "Double backticks should be parsed as Hylo references, and inner backticks should be part of the content."
    )

    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("``MyType.`type` ``"),
      .document([
        .paragraph(
          Text([
            .custom(HyloReference("MyType.`type` "))
          ]))
      ]),
      "Double backticks should be parsed as Hylo references, and inner backticks should be part of the content."
    )
  }

  func testDummyHTMLAndDescriptionGeneration() {
    XCTAssertEqual(
      HyloReference("MyType.Element").generateHtml(via: DummyCustomHTMLRenderer()),
      "BEGINMyType.ElementEND"
    )
    XCTAssertEqual(
      DummyCustomHTMLRenderer().generate(
        doc: HyloDocMarkdownParser.standard.parse("``MyType.Element``")
      ).trimmingSuffix(while: { $0.isWhitespace }),
      "<p>BEGINMyType.ElementEND</p>"
    )

    XCTAssertEqual(
      HyloReference("MyType.Element").description,
      "hyloReference(MyType.Element)"
    )
    XCTAssertEqual(
      HyloReference("MyType.Element").debugDescription,
      "hyloReference(MyType.Element)"
    )
    XCTAssertEqual(
      HyloReference("MyType.Element").rawDescription,
      "MyType.Element"
    )
  }

  func testOriginalFunctionalityStillWorks() {
    // url
    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("<https://google.com>"),
      .document([
        .paragraph(Text([.autolink(.uri, "https://google.com")]))
      ]),
      "autolink url"
    )

    // tel
    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("<tel:123456>"),
      .document([
        .paragraph(Text([.autolink(.uri, "tel:123456")]))
      ]),
      "autolink tel"
    )

    // email
    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("<a@b.com>"),
      .document([
        .paragraph(Text([.autolink(.email, "a@b.com")]))
      ]),
      "autolink email"
    )

    // html tags
    XCTAssertEqual(
      HyloDocMarkdownParser.standard.parse("<img src=\"hello\">"),
      .document([
        .paragraph(Text([.html("img src=\"hello\"")]))
      ]),
      "html tag"
    )
  }

}

extension Text {
  init(_ fragments: [TextFragment]) {
    self.init()
    fragments.forEach { self.append(fragment: $0) }
  }
}
