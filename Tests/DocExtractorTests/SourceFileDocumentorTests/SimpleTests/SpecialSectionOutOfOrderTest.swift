import DocExtractor
import DocumentationDB
import FrontEnd
import HDCUtils
import TestUtils
import XCTest

final class SpecialSectionOutOfOrderTest: XCTestCase {

  struct OutOfOrderErrorPayload {
    let found: SpecialSectionType
    let expectedBefore: SpecialSectionType
  }
  func testOutOfOrder(
    in sourceFile: SourceFile, expectedErrors: [OutOfOrderErrorPayload], file: StaticString = #filePath, line: UInt = #line
  ) throws {
    let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
    let sourceFileDocumentor = RealSourceFileDocumentor(
      commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)

    let ast = try checkNoDiagnostic { d in
      try AST(fromSingleSourceFile: sourceFile, diagnostics: &d)
    }

    var store = SymbolDocStore()

    var d = HDCDiagnosticSet()
    let _ = sourceFileDocumentor.document(
      ast: ast,
      translationUnitId: ast.resolveTranslationUnit(by: sourceFile.baseName)!,
      into: &store,
      diagnostics: &d
    )

    let outOfOrderDiagnostics = d.elements.filter { $0 is OutOfOrderError }
    XCTAssertEqual(
      expectedErrors.count, outOfOrderDiagnostics.count,
      "The number of out of order diagnostics does not match the expected count. Diagnostic: \n\(outOfOrderDiagnostics.map { $0.description }.joined(separator: "\n"))",
      file: file, line: line)

    for expectedError in expectedErrors {
      let match = outOfOrderDiagnostics.first { diagnostic in
        let error = diagnostic as! OutOfOrderError
        return error.found == expectedError.found && error.expectedBefore == expectedError.expectedBefore
      }
      XCTAssertNotNil(
        match,
        "Expected out of order error with found: \(expectedError.found) and expectedBefore: \(expectedError.expectedBefore) not found.",
        file: file, line: line
      )
    }
  }

  func testOutOfOrder1() throws {
    try testOutOfOrder(
      in: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Generic T: This is a generic.
        /// # Parameter x: This is a parameter.
        fun id(x: Int) -> Int { x }
        """,
      expectedErrors: [
        .init(found: .parameter, expectedBefore: .generic)
      ])
  }

  func testOutOfOrder2() throws {
    try testOutOfOrder(
      in: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Returns: something.
        /// # Parameter x: This is a parameter.
        /// # Generic y: This is a generic parameter.
        fun id(x: Int) -> Int { x }
        """,
      expectedErrors: [
        .init(found: .parameter, expectedBefore: .returns),
        .init(found: .generic, expectedBefore: .returns),
      ])
  }
  func testOutOfOrder3() throws {
    try testOutOfOrder(
      in: """
        /// Summary of subscript.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Parameter param: sample param desc
        /// # Yields: some stuff.
        /// # Projects:
        ///   - Insecurity
        /// # Complexity: O(2)
        subscript foo(param: Int): T { }
        """,
      expectedErrors: [])
  }

  func testInOrder() throws {
    try testOutOfOrder(
      in: """
        /// Summary of function.
        /// 
        /// This is the description.
        /// - Note: This is still the description.
        /// # Parameter x: This is a parameter.
        /// # Generic y: This is a generic parameter.
        /// # Returns: something.
        fun id(x: Int) -> Int { x }
        """,
      expectedErrors: []
    )
  }
}
