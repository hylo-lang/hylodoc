import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class FuncExtractionTest: XCTestCase {
  func testFuncExtractionInlineParams() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Parameter x: This is a parameter.
        /// # Generic T: This is a generic.
        fun id<T: Movable>(_ x: T) -> T { x }
        """, named: "testFile4.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile4.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    let declId = ast.resolveFunc(by: "id")!
    let myTypeDoc = store.functionDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myTypeDoc.documentation.common.common.summary?.description, what: "Summary of function.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.description,
      what: "This is the description.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.description,
      what: "Note: This is still the description.")
    assertContains(
      myTypeDoc.documentation.parameters.first?.value.description.description,
      what: "This is a parameter.")
    assertContains(
      myTypeDoc.documentation.genericParameters.first?.value.description.description,
      what: "This is a generic.")
  }

  func testFuncExtractionSectionParams() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Parameters: 
        ///   - x: This is a parameter.
        /// # Generics: 
        ///   - T: This is a generic.
        fun id<T: Movable>(_ x: T) -> T { x }
        """, named: "testFile5.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile5.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    let declId = ast.resolveFunc(by: "id")!
    let myTypeDoc = store.functionDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myTypeDoc.documentation.common.common.summary?.description, what: "Summary of function.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.description,
      what: "This is the description.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.description,
      what: "Note: This is still the description.")
    assertContains(
      myTypeDoc.documentation.parameters.first?.value.description.description,
      what: "This is a parameter.")
    assertContains(
      myTypeDoc.documentation.genericParameters.first?.value.description.description,
      what: "This is a generic.")
  }

  func testFuncExtractionWrongParams() {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let sourceFile = SourceFile(
      synthesizedText: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Parameters: 
        ///   - y: This is a parameter.
        /// # Generics: 
        ///   - T: This is a generic.
        fun id<T: Movable>(_ x: T) -> T { x }
        """, named: "testFile6.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile6.hylo")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertContains(diagnostics.description, what: "warning")
  }
}
