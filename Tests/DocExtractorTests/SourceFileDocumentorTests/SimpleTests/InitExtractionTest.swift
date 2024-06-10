import DocExtractor
import DocumentationDB
import FrontEnd
import XCTest

final class InitExtractionTest: XCTestCase {
  func testInitExtraction() {
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


        /// Summary of typealias.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        type Vector2 {
          public var x: Float64
          public var y: Float64

          /// Summary of init.
          /// 
          /// This is the description1.
          /// - Note: This is still the description1.
          /// # Preconditions:
          ///   - Parameters exist
          /// # Postconditions:
          ///   - Type exists
          /// # Throws big errors!
          public init(x: Float64, y: Float64) {
            self.x = x
            self.y = y
          }
        }
        """, named: "testFile.hylo")

    var diagnostics = DiagnosticSet()
    let ast = AST(fromSingleSourceFile: sourceFile, diagnostics: &diagnostics)

    var store = SymbolDocStore()

    let fileLevel = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: "testFile")!,
      into: &store,
      diagnostics: &diagnostics
    )

    assertNoDiagnostics(diagnostics)

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveInit(by: "Vector2")!
    let myTypeDoc = store.initializerDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myTypeDoc.documentation.common.common.summary?.debugDescription, what: "Summary of init.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "This is the description1.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "Note: This is still the description1.")
    assertContains(
      myTypeDoc.documentation.common.throwsInfo.first?.description.description, what: "big errors!")
    assertContains(
      myTypeDoc.documentation.common.preconditions.first?.description.description,
      what: "Parameters exist")
    assertContains(
      myTypeDoc.documentation.common.postconditions.first?.description.description,
      what: "Type exists")
  }
}
