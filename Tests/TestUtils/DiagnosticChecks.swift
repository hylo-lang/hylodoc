import FrontEnd
import HDCUtils
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

/// Returns the result of invoking `f` on an initially-empty diagnostic set, reporting any
/// diagnostics added and/or thrown as XCTest issues.
///
/// Adapted from the Hylo Compiler's test utils.
public func checkNoHDCDiagnostic<R>(
  f: (inout HDCDiagnosticSet) throws -> R, testFile: StaticString = #filePath, line: UInt = #line
) rethrows -> R {
  var d = HDCDiagnosticSet()
  do {
    let r = try f(&d)
    checkHDCEmpty(d, file: testFile, line: line)
    return r
  } catch let d1 as HDCDiagnosticSet {
    XCTAssertEqual(
      d1, d, "thrown diagnostics don't match mutated diagnostics",
      file: testFile, line: line)
    checkHDCEmpty(d, file: testFile, line: line)
    throw d
  }
}

public func expectHDCDiagnostic<R, D: HDCDiagnostic>(
  f: (inout HDCDiagnosticSet) throws -> R,
  testFile: StaticString = #filePath,
  line: UInt = #line,
  expectedDiagnostic: D.Type,
  expectedSite: SourceRange? = nil,
  expectedMessage: String? = nil
) rethrows -> R {
  var d = HDCDiagnosticSet()
  do {
    let r = try f(&d)
    XCTAssertFalse(
      d.elements.isEmpty, "Expected diagnostics, but none were emitted", file: testFile, line: line)
    return r
  } catch let d1 as HDCDiagnosticSet {
    XCTAssertEqual(
      d1, d, "thrown diagnostics don't match mutated diagnostics",
      file: testFile, line: line)
    XCTAssertFalse(
      d.elements.isEmpty, "Expected diagnostics, but none were emitted", file: testFile, line: line)
    XCTAssertTrue(
      d.elements.contains { element in
        guard let diagnostic = element as? D else { return false }
        return (expectedSite == nil || diagnostic.site == expectedSite)
          && (expectedMessage == nil || diagnostic.message == expectedMessage)
      },
      "Expected diagnostic of type \(expectedDiagnostic) with message \(String(describing: expectedMessage)) not found at site \(String(describing: expectedSite))",
      file: testFile, line: line)
    throw d
  }
}

/// Reports any diagnostics in `s` as XCTest issues.
public func checkHDCEmpty(_ s: HDCDiagnosticSet, file: StaticString = #filePath, line: UInt = #line)
{
  if !s.elements.isEmpty {
    XCTFail(
      "Unexpected diagnostics: \n\(s.elements.map{ "- " + $0.description }.joined(separator: "\n\n"))",
      file: file, line: line
    )
  }
}
