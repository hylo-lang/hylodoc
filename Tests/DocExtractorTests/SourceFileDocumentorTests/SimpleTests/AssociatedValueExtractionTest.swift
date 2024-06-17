import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class AssociatedValueExtractionTest: XCTestCase {
  func testAssociatedValueExtraction() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// # File-level:
        /// This is the summary of the file.
        /// 
        /// Hello
        /// 
        /// world
        ///  - in the 
        ///  - description


        /// Summary of typealias.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        trait A {
          
          /// Summary of associated value.
          /// 
          /// This is the description1.
          /// - Note: This is still the description1.
          value foo
        }
        """, named: "testFile2.hylo")

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let fileLevel = checkNoDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile2.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveAssociatedValue(by: "foo")!
    let myTypeDoc = store.associatedValueDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.description, what: "Summary of associated value.")
    assertContains(myTypeDoc.common.description?.description, what: "This is the description1.")
    assertContains(
      myTypeDoc.common.description?.description, what: "Note: This is still the description1.")
  }
}
