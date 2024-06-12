import DocExtractor
import DocumentationDB
import FrontEnd
import XCTest
import TestUtils

final class TraitExtractionTest: XCTestCase {
  func testTraitExtraction() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

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
        /// # Invariant: A must be capitalized
        trait A {
          type B
        }
        """, named: "testFile12.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let fileLevel = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile12.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveTrait(by: "A")!
    let myTypeDoc = store.traitDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(myTypeDoc.common.summary?.debugDescription, what: "Summary of typealias.")
    assertContains(myTypeDoc.common.description?.debugDescription, what: "This is the description.")
    assertContains(
      myTypeDoc.common.description?.debugDescription, what: "Note: This is still the description.")
    assertContains(
      myTypeDoc.invariants.first?.description.debugDescription, what: "A must be capitalized")
  }
}
