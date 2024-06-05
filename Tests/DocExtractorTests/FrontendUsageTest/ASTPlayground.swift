import DocumentationDB
import Foundation
import FrontEnd
import StandardLibraryCore
import XCTest

final class ASTPlayground: XCTestCase {
  func testASTWalking() {

    var diagnostics = DiagnosticSet()
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    guard
      let _ = try? ast.addModule(
        fromSingleSourceFile: .init(
          synthesizedText: """
              type Vector: Deinitializable {
                var x: Int
                fun myMethod(m: Int) {
                  inout {
                    &x += m
                  }
                }
              }

            """, named: "hello.hylo"), diagnostics: &diagnostics, moduleName: "hello")
    else {
      XCTFail("Failed to add module")
      print(diagnostics)
      return
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

    guard
      let a = try? TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false, reportingDiagnosticsTo: &diagnostics,
        tracingInferenceIf: { a, b in false })
    else {
      XCTFail("Failed to type check")
      print(diagnostics)
      return
    }

    let _ = a
  }

}
