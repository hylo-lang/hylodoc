import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import XCTest

final class CommentExtractorTest: XCTestCase {

  func expectSuccess(
    code: String,
    file: StaticString = #file, line: UInt = #line  //
  ) -> (ast: AST, doc: DocumentedFile)? {
    var diagnostics = DiagnosticSet()
    let sourceFile = SourceFile(stringLiteral: code)
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)
    if !diagnostics.isEmpty {
      XCTFail(
        "Errors while frontend parsing: \(diagnostics)",
        file: file, line: line)
      return nil
    }

    let commentExtractor = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())

    guard let doc = commentExtractor.parse(sourceFile: sourceFile, diagnostics: &diagnostics)
    else {
      XCTFail(
        "Comment extraction failed with the following diagnostics: \(diagnostics)",
        file: file, line: line)
      return nil
    }

    return (ast, doc)
  }

  func testOneLineCommentExtraction() {
    let code =
      """
      /// This is a comment.
      public typealias MyType = Int
      """
    guard let (ast, doc) = expectSuccess(code: code)
    else { return }

    let declId = ast.resolveTypeAlias(by: "MyType")!
    guard let symbolComment = doc.symbolComments[ast[declId].site.startIndex] else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    XCTAssertEqual(symbolComment.value.contentBeforeSections.count, 1)
    XCTAssertEqual(symbolComment.value.specialSections.count, 0)
    assertContains(symbolComment.value.contentBeforeSections.description, what: "This is a comment.")
    assertNotContains(symbolComment.value.contentBeforeSections.description, what: "public typealias")
  }

  // todo write more tests
}
