import DocExtractor
import DocumentationDB
import FrontEnd
import XCTest
import TestUtils

final class OperatorExtractionTest: XCTestCase {
  func testOperatorExtraction() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(commentParser: commentParser)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of typealias.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        operator infix+ : addition
        """, named: "testFile.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

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
