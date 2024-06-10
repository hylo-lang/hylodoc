import DocExtractor
import DocumentationDB
import FrontEnd
import XCTest
import TestUtils

final class SubscriptExtractionTest: XCTestCase {
  func testSubscriptDeclExtraction() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(commentParser: commentParser)

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


        /// Summary of subscript.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Yields some stuff.
        /// # Parameter param: sample param desc
        subscript foo(param: Int): T { 
          /// Summary of subscript implementation.
          /// 
          /// This is the description2.
          /// - Note: This is still the description2.
          /// # Yields some other stuff.
          T() 
        }
        """, named: "testFile.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let fileLevel = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveSubscriptDecl(by: "foo")!
    let myTypeDoc = store.subscriptDeclDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myTypeDoc.documentation.common.common.summary?.debugDescription, what: "Summary of subscript."
    )
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "This is the description.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "Note: This is still the description.")
    assertContains(myTypeDoc.yields.first?.description.description, what: "some stuff.")
    assertContains(
      myTypeDoc.documentation.parameters.first?.value.description.description,
      what: "sample param desc")

    let implId = ast[declId].impls.first!
    let myImplDoc = store.subscriptImplDocs[implId]

    guard let myImplDoc = myImplDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myImplDoc.documentation.common.summary?.debugDescription,
      what: "Summary of subscript implementation.")
    assertContains(
      myImplDoc.documentation.common.description?.debugDescription,
      what: "This is the description2.")
    assertContains(
      myImplDoc.documentation.common.description?.debugDescription,
      what: "Note: This is still the description2.")
    assertContains(myImplDoc.yields.first?.description.description, what: "some other stuff")
  }
}
