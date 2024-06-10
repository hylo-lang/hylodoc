import DocExtractor
import DocumentationDB
import FrontEnd
import XCTest
import TestUtils

final class AssociatedTypeExtractionTest: XCTestCase {
  func testAssociatedTypeExtraction() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(commentParser: commentParser)

    let sourceFile = SourceFile(
      synthesizedText: """
        trait A {
          
          /// Summary of associated type.
          /// 
          /// This is the description.
          /// - Note: This is still the description.
          type B
        }
        """, named: "testFile1.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile1.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    let declId = ast.resolveAssociatedType(by: "B")!
    let myTypeDoc = store.associatedTypeDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of associated type.")
    assertContains(myTypeDoc.common.description?.debugDescription, what: "This is the description.")
    assertContains(
      myTypeDoc.common.description?.debugDescription, what: "Note: This is still the description.")
  }
}
