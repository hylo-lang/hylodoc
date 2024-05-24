import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import XCTest

final class CommentExtractorTest: XCTestCase {

  public func testCommentExtraction() {
    let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("ExampleModule")

    let productName = "myProduct"

    /// An instance that includes just the standard library.
    var ast = AST(ConditionalCompilationFactors())

    var diagnostics = DiagnosticSet()

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      productName,
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    struct ASTWalkingVisitor: ASTWalkObserver {
      let commentParser = ExampleCommentParser()
      var commentedFile: CommentedFile?

      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
        // pattern match the type of node:
        if let d = ProductTypeDecl.ID(n) {
          let productTypeDecl = ast[d]
          print("ProductTypeDecl found: " + productTypeDecl.baseName)

          if let comment = commentedFile?.getSymbolComment(productTypeDecl.site.startIndex) {
            print(comment)
          }
        } else if let d = ModuleDecl.ID(n) {
          let moduleInfo = ast[d]
          print("Module found: " + moduleInfo.baseName)
        } else if let d = TranslationUnit.ID(n) {
          let translationUnit = ast[d]
          print("TU found: " + translationUnit.site.file.baseName)

          commentedFile = CommentedFile(translationUnit.site.file, commentParser)
          if let fileComment = commentedFile?.fileComment {
            print(fileComment)
          }
        } else if let d = FunctionDecl.ID(n) {
          let functionDecl = ast[d]
          print("Function found: " + (functionDecl.identifier?.value ?? "*unnamed*"))

          if let comment = commentedFile?.getSymbolComment(functionDecl.site.startIndex) {
            print(comment)
          }
        }
        return true
      }
    }
    var visitor = ASTWalkingVisitor()
    for m in ast.modules {
      ast.walk(m, notifying: &visitor)
    }
  }

}

public struct ExampleCommentParser: LowLevelCommentParser {
  public func parse(_ commentLines: [String]) -> LowLevelInfo {
    if commentLines[0].contains("File-Level") {
      let fileInfo: FileLevelInfo = FileLevelInfo(commentLines.joined())
      return LowLevelInfo.FileLevel(info: fileInfo)
    }

    let symbolInfo = SymbolDocInfo(commentLines.joined())
    return LowLevelInfo.SymbolDoc(info: symbolInfo)
  }
}
