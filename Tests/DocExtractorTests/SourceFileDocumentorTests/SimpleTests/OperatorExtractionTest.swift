import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class OperatorExtractionTest: XCTestCase {
  func testOperatorExtraction() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of typealias.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        operator infix+ : addition
        """, named: "testFile9.hylo")

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let _ = checkNoHDCDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile9.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

    let declId = ast.resolveOperator()!.first!
    let myTypeDoc = store.operatorDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of typealias.")
    assertContains(myTypeDoc.common.description?.debugDescription, what: "This is the description.")
    assertContains(
      myTypeDoc.common.description?.debugDescription, what: "Note: This is still the description.")
  }
}
