import DocumentationDB
import Foundation
import FrontEnd
import HyloStandardLibrary
import TestUtils
import XCTest

final class ASTPlayground: XCTestCase {
  func testASTWalking() throws {

    var ast = try checkNoDiagnostic { d in try AST.loadStandardLibraryCore(diagnostics: &d) }

    let source: SourceFile =
      """
        type Vector: Deinitializable {
          var x: Int
          fun myMethod(m: Int) {
            inout {
              &x += m
            }
          }
        }
      """
    let _ = try checkNoDiagnostic { d in
      try ast.addModule(fromSingleSourceFile: source, diagnostics: &d, moduleName: "hello")
    }

    struct ASTWalker: ASTWalkObserver {
      var indent: Int = 0
      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
        let indentation = String(repeating: "  ", count: indent)
        print(indentation + n.description)
        indent += 1
        return true
      }

      mutating func willExit(_ n: AnyNodeID, in ast: AST) {
        indent -= 1
      }
    }

    var walker = ASTWalker()
    for m in ast.modules where ast[m].baseName == "hello" {
      ast.walk(m, notifying: &walker)
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast),
        inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { a, b in false })
    }
    let _ = typedProgram
  }

}
