import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class SubscriptExtractionTest: XCTestCase {
  func testSubscriptDeclExtraction() throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    // todo projects and yields should not be possible to add to a subscript at the same time.
    let sourceFile: SourceFile = 
     """
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
        /// # Parameter param: sample param desc
        /// # Yields: some stuff.
        /// # Projects:
        ///   - Insecurity
        /// # Complexity: O(2)
        subscript foo(param: Int): T { 
          /// Summary of subscript implementation.
          /// 
          /// This is the description2.
          /// - Note: This is still the description2.
          /// # Yields: some other stuff.
          /// # Projects:
          ///   - Insecurity
          /// # Complexity: O(2)
          T() 
        }
        """

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let fileLevel = checkNoHDCDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: sourceFile.baseName)!,
        into: &store,
        diagnostics: &d
      )
    }
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
    assertContains(myTypeDoc.projectsInfo.first?.description.description, what: "Insecurity")
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
