import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class ProductTypeExtractionTest: XCTestCase {
  func testProductTypeExtractionInlineSingleInvariant() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of the product type.
        ///
        /// This is the description of the product type.
        /// # Invariant: x and y must always be positive.
        type A {
          var x: Int
          var y: Int
          fun foo() -> Int { x.copy() }
        }
        """, named: "testFile.hylo")

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let _ = checkNoDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

    let declId = ast.resolveProductType(by: "A")!
    let myTypeDoc = store.productTypeDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of the product type.")
    assertContains(
      myTypeDoc.common.description?.debugDescription,
      what: "This is the description of the product type.")

    assertContains(
      myTypeDoc.invariants.map { $0.description.debugDescription }.joined(),
      what: "x and y must always be positive.")
  }

  func testProductTypeExtractionListInvariant() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of the product type.
        ///
        /// This is the description of the product type.
        /// # Invariants: 
        ///   - x and y must always be positive.
        type A {
          var x: Int
          var y: Int
          fun foo() -> Int { x.copy() }
        }
        """, named: "testFile10.hylo")

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let _ = checkNoDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile10.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

    let declId = ast.resolveProductType(by: "A")!
    let myTypeDoc = store.productTypeDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of the product type.")
    assertContains(
      myTypeDoc.common.description?.debugDescription,
      what: "This is the description of the product type.")

    assertContains(
      myTypeDoc.invariants.map { $0.description.debugDescription }.joined(),
      what: "x and y must always be positive.")
  }
}
