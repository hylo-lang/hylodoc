import DocExtractor
import DocumentationDB
import FrontEnd
import HDCUtils
import TestUtils
import XCTest

final class BindingExtractionTest: XCTestCase {
  func testBindingExtraction() throws {
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


        /// Summary of binding.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Invariant: foo must be positive
        let foo = 5
        """, named: "testFile3.hylo")

    var diagnostics = DiagnosticSet()
    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)
    }

    var store = SymbolDocStore()

    let fileLevel = checkNoHDCDiagnostic {
      hd in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile3.hylo")!,
        into: &store,
        diagnostics: &hd
      )
    }

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveBinding()!.first!
    let myTypeDoc: BindingDocumentation? = store.bindingDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of binding.")
    assertContains(myTypeDoc.common.description?.debugDescription, what: "This is the description.")
    assertContains(
      myTypeDoc.common.description?.debugDescription, what: "Note: This is still the description.")
    assertContains(
      myTypeDoc.invariants.first!.description.description, what: "foo must be positive")
  }
}
