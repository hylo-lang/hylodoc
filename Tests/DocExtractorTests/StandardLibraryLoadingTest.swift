import HyloStandardLibrary
import TestUtils
import XCTest

@testable import FrontEnd

final class StandardLibraryCoreLoadingTest: XCTestCase {
  func testCoreCanBeLoaded() throws {
    // parse standard library
    let ast = try checkNoDiagnostic { d in
      try AST.loadStandardLibraryCore(diagnostics: &d)
    }

    XCTAssertNotNil(ast.coreTrait("Deinitializable"), "core traits are not loaded properly")
    XCTAssertNil(
      ast.resolveProductType(by: "Array"), "symbol was loaded from outside the core library")

    // type check standard library
    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in false }
      )
    }

    XCTAssertFalse(typedProgram.ast.modules.isEmpty)
  }

  func testFullStdLibCanBeLoaded() throws {
    // parse standard library
    let ast = try checkNoDiagnostic { d in
      try AST.loadStandardLibrary(diagnostics: &d)
    }

    XCTAssertNotNil(ast.coreTrait("Deinitializable"), "core traits are not loaded properly")
    XCTAssertNotNil(
      ast.resolveProductType(by: "Array"),
      "symbol was not loaded from outside the core library inside the standard library")

    // type check standard library
    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in false }
      )
    }

    XCTAssertFalse(typedProgram.ast.modules.isEmpty)
  }
}
