import StandardLibraryCore
import XCTest

@testable import FrontEnd

final class StandardLibraryCoreLoadingTest: XCTestCase {
  func testStdLibCanBeLoaded() {
    var diagnostics = DiagnosticSet()

    let ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in false })

    XCTAssertFalse(typedProgram.ast.modules.isEmpty)

    print(diagnostics.elements)
    XCTAssertTrue(diagnostics.isEmpty)
  }
}
