import DocExtractor
import DocumentationDB
import FrontEnd
import TestUtils
import XCTest

final class MethodExtractionTest: XCTestCase {
  func testMethodExtraction() throws {
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


        /// Summary of typealias.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        type Vector2 {
          public var x: Float64
          public var y: Float64
          public memberwise init

          /// Summary of method.
          /// 
          /// This is the description1.
          /// - Note: This is still the description1.
          /// # Parameter delta: it is a vector
          /// # Returns: another vector!
          public fun offset(by delta: Vector2) -> Vector2 {
            /// Summary of method implementation.
            /// 
            /// This is the description2.
            /// - Note: This is still the description2.
            /// # Returns:
            ///   - something
            /// # Throws:
            ///   - something else
            let {
              Vector2(x: x + delta.x, y: y + delta.y)
            }
          }
        }
        """, named: "testFile8.hylo")

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    let fileLevel = checkNoDiagnostic { d in
      sourceFileDocumentor.document(
        ast: ast,
        translationUnitId: ast.resolveTranslationUnit(by: "testFile8.hylo")!,
        into: &store,
        diagnostics: &d
      )
    }

    assertContains(fileLevel.summary?.debugDescription, what: "This is the summary of the file.")
    assertContains(fileLevel.description?.debugDescription, what: "Hello")
    assertContains(fileLevel.description?.debugDescription, what: "world")
    assertContains(fileLevel.description?.debugDescription, what: "in the")
    assertContains(fileLevel.description?.debugDescription, what: "description")

    let declId = ast.resolveMethodDecl(by: "offset")!
    let myTypeDoc = store.methodDeclDocs[declId]

    guard let myTypeDoc = myTypeDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myTypeDoc.documentation.common.common.summary?.debugDescription, what: "Summary of method.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "This is the description1.")
    assertContains(
      myTypeDoc.documentation.common.common.description?.debugDescription,
      what: "Note: This is still the description1.")
    assertContains(
      myTypeDoc.documentation.parameters.first?.value.description.description,
      what: "it is a vector")
    assertContains(myTypeDoc.returns.first?.description.description, what: "another vector!")

    let implId = ast[declId].impls.first!
    let myImplDoc = store.methodImplDocs[implId]

    guard let myImplDoc = myImplDoc else {
      XCTFail("Expected a symbol comment, got nil")
      return
    }

    assertContains(
      myImplDoc.documentation.common.summary?.debugDescription,
      what: "Summary of method implementation.")
    assertContains(
      myImplDoc.documentation.common.description?.debugDescription,
      what: "This is the description2.")
    assertContains(
      myImplDoc.documentation.common.description?.debugDescription,
      what: "Note: This is still the description2.")
    assertContains(
      myImplDoc.documentation.throwsInfo.first?.description.description, what: "something else")
    assertContains(myImplDoc.returns.first?.description.description, what: "something")
  }
}
