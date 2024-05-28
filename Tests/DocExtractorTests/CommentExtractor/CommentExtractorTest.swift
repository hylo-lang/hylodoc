import DocumentationDB
import Foundation
import FrontEnd
import XCTest

@testable import DocExtractor

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

  func expectFail(
    code: String,
    message: String,
    file: StaticString = #file, line: UInt = #line  //
  ) {
    var diagnostics = DiagnosticSet()
    let sourceFile = SourceFile(stringLiteral: code)
    let _ = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)
    if !diagnostics.isEmpty {
      XCTFail(
        "Errors while frontend parsing: \(diagnostics)",
        file: file, line: line)
      return
    }

    let commentExtractor = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())

    guard
      commentExtractor.parse(sourceFile: sourceFile, diagnostics: &diagnostics) == nil
        && !diagnostics.isEmpty
    else {
      XCTFail(message)
      return
    }
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
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "This is a comment.")
    assertNotContains(
      symbolComment.value.contentBeforeSections.description, what: "public typealias")
  }

  // todo write more tests

  func testMultiLineCommentExtraction() {
    let code =
      """
      /// This is a multi-line comment.
      /// It spans multiple lines.
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
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "This is a multi-line comment.")
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "It spans multiple lines.")
  }

  func testMultipleSymbolComments() {
    let code =
      """
      /// First comment.
      public typealias TypeA = Int

      /// Second comment.
      public typealias TypeB = String
      """
    guard let (ast, doc) = expectSuccess(code: code)
    else { return }

    let declIdA = ast.resolveTypeAlias(by: "TypeA")!
    let declIdB = ast.resolveTypeAlias(by: "TypeB")!

    guard let symbolCommentA = doc.symbolComments[ast[declIdA].site.startIndex] else {
      XCTFail("Expected a symbol comment for TypeA, got nil")
      return
    }
    guard let symbolCommentB = doc.symbolComments[ast[declIdB].site.startIndex] else {
      XCTFail("Expected a symbol comment for TypeB, got nil")
      return
    }

    assertContains(symbolCommentA.value.contentBeforeSections.description, what: "First comment.")
    assertContains(symbolCommentB.value.contentBeforeSections.description, what: "Second comment.")
  }

  func testCommentMissingSymbol() {
    let code =
      """
      /// Invalid comment without symbol
      """

    expectFail(code: code, message: "Expected to fail due to comment missing symbol")
  }

  func testFileLevelCommentExtraction() {
    let code =
      """
      /// # file-level
      /// This is a file-level comment.
      public typealias MyType = Int
      """
    guard let (_, doc) = expectSuccess(code: code)
    else { return }

    XCTAssertNotNil(doc.fileLevel)
    XCTAssertEqual(doc.fileLevel?.value.contentBeforeSections.count, 0)
    XCTAssertEqual(doc.fileLevel?.value.specialSections.count, 1)
    let fileLevelSection = doc.fileLevel!.value.specialSections[0]
    XCTAssertEqual(fileLevelSection.name, "file-level")
    assertContains(fileLevelSection.blocks.description, what: "This is a file-level comment.")
  }

  func testFileLevelCommentEndOfFile() {
    let code =
      """
      public typealias MyType = Int

      /// # file-level
      /// This is a file-level comment.
      """
    guard let (_, doc) = expectSuccess(code: code)
    else { return }

    XCTAssertNotNil(doc.fileLevel)
    XCTAssertEqual(doc.fileLevel?.value.contentBeforeSections.count, 0)
    XCTAssertEqual(doc.fileLevel?.value.specialSections.count, 1)
    let fileLevelSection = doc.fileLevel!.value.specialSections[0]
    XCTAssertEqual(fileLevelSection.name, "file-level")
    assertContains(fileLevelSection.blocks.description, what: "This is a file-level comment.")
  }
  func testMultipleFileLevelComments() {
    let code =
      """
      /// # file-level
      public typealias TypeA = Int

      /// # file-level
      public typealias TypeB = Int
      """

    expectFail(code: code, message: "Expected to fail due to double file-level comments")
  }

  func testMixedCommentTypes() {
    let code =
      """
      /// # file-level
      /// This is a file-level comment.
      public typealias TypeA = Int

      /// This is a symbol comment.
      public typealias TypeB = String
      """
    guard let (ast, doc) = expectSuccess(code: code)
    else { return }

    XCTAssertNotNil(doc.fileLevel)
    XCTAssertEqual(doc.fileLevel?.value.contentBeforeSections.count, 0)
    let fileLevelSection = doc.fileLevel!.value.specialSections[0]
    XCTAssertEqual(fileLevelSection.name, "file-level")
    assertContains(fileLevelSection.blocks.description, what: "This is a file-level comment.")

    let declIdA = ast.resolveTypeAlias(by: "TypeA")!
    let declIdB = ast.resolveTypeAlias(by: "TypeB")!
    XCTAssertNil(doc.symbolComments[ast[declIdA].site.startIndex])
    guard let symbolComment = doc.symbolComments[ast[declIdB].site.startIndex] else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    XCTAssertEqual(symbolComment.value.contentBeforeSections.count, 1)
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "This is a symbol comment.")
  }

  func testNoDocumentationComment() {
    let code =
      """
      // This is a regular comment.
      public typealias MyType = Int
      """
    guard let (ast, doc) = expectSuccess(code: code)
    else { return }

    let declId = ast.resolveTypeAlias(by: "MyType")!
    XCTAssertNil(doc.symbolComments[ast[declId].site.startIndex])
  }

  func testCommentStartingOnSameLineAsCode() {
    let code =
      """
      public typealias TypeA = Int /// This is a comment.
      /// Continuation of the comment.
      public typealias TypeB = String
      """
    guard let (ast, doc) = expectSuccess(code: code)
    else { return }

    let declIdA = ast.resolveTypeAlias(by: "TypeA")!
    XCTAssertNil(doc.symbolComments[ast[declIdA].site.startIndex])

    let declIdB = ast.resolveTypeAlias(by: "TypeB")!
    guard let symbolComment = doc.symbolComments[ast[declIdB].site.startIndex] else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    XCTAssertEqual(symbolComment.value.contentBeforeSections.count, 1)
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "This is a comment.")
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "Continuation of the comment.")
  }

  func testCommentSeparatedByWhitespaceBeforeTarget() {
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
    assertContains(
      symbolComment.value.contentBeforeSections.description, what: "This is a comment.")
  }

  func testCommentNotAligned() {
    let code =
      """
      /// This is a comment
        /// still the comment
      /// end of comment

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
    assertContains(symbolComment.value.contentBeforeSections.description, what: "This is a comment")
    assertContains(symbolComment.value.contentBeforeSections.description, what: "still the comment")
    assertContains(symbolComment.value.contentBeforeSections.description, what: "end of comment")
  }
}
