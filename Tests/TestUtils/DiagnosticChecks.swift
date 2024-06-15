import FrontEnd
import XCTest

/// Returns the result of invoking `f` on an initially-empty diagnostic set, reporting any
/// diagnostics added and/or thrown as XCTest issues.
///
/// Adapted from the Hylo Compiler's test utils.
public func checkNoDiagnostic<R>(
  f: (inout DiagnosticSet) throws -> R, testFile: StaticString = #filePath, line: UInt = #line
) rethrows -> R {
  var d = DiagnosticSet()
  do {
    let r = try f(&d)
    checkEmpty(d)
    return r
  } catch let d1 as DiagnosticSet {
    XCTAssertEqual(
      d1, d, "thrown diagnostics don't match mutated diagnostics",
      file: testFile, line: line)
    checkEmpty(d)
    throw d
  }
}

/// Reports any diagnostics in `s` as XCTest issues.
public func checkEmpty(_ s: DiagnosticSet) {
  if !s.elements.isEmpty {
    XCTFail(
      "Unexpected diagnostics: \n\(s.elements.map{ "- " + $0.description }.joined(separator: "\n\n"))"
    )
  }
}
