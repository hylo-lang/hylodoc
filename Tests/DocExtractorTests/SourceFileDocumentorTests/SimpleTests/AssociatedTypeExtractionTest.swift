import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class AssociatedTypeExtractionTest: XCTestCase {
  func testAssociatedTypeExtraction() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

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

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let _ = checkNoHDCDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile1.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

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
