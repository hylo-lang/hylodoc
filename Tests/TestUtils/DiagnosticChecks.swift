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

/// Assert that there are some diagnostics present after running `f` and that the diagnostics are consistent with the thrown diagnostics.
public func checkDiagnosticPresent<R>(
  f: (inout DiagnosticSet) throws -> R, testFile: StaticString = #filePath, line: UInt = #line,
  expectedMessages: [String] = []
) rethrows -> R {
  var d = DiagnosticSet()
  do {
    let r = try f(&d)
    XCTAssertFalse(
      d.elements.isEmpty, "Expected diagnostics, but none were emitted", file: testFile, line: line)
    return r
  } catch let d1 as DiagnosticSet {
    XCTAssertEqual(
      d1, d, "thrown diagnostics don't match mutated diagnostics",
      file: testFile, line: line)
    XCTAssertFalse(
      d.elements.isEmpty, "Expected diagnostics, but none were emitted", file: testFile, line: line)
    for message in expectedMessages {
      assertContains(d.description, what: message, file: testFile, line: line)
    }
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
