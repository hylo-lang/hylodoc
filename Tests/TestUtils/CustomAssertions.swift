import FrontEnd
import XCTest

public func assertContains(
  _ string: String, what: String,
  file: StaticString = #file, line: UInt = #line
) {
  if !string.contains(what) {
    XCTFail(
      "String expected to contain: \n" + ANSIColors.green("```\n\(what)\n```\n")
        + "but it was actually:\n" + ANSIColors.red("```\n\(string)\n```"),
      file: file, line: line)
    return
  }
}

public func assertContains(
  _ string: String?, what: String,
  file: StaticString = #file, line: UInt = #line
) {
  guard let string = string else {
    XCTFail(
      "String is nil, but expected to be:\n" + ANSIColors.green("```\n\(what)\n\n```\n"),
      file: file, line: line)
    return
  }
  assertContains(string, what: what, file: file, line: line)
}

public func assertNotContains(
  _ string: String, what: String,
  file: StaticString = #file, line: UInt = #line
) {
  if string.contains(what) {
    XCTFail(
      "String expected NOT to contain: \n" + ANSIColors.yellow("```\n\(what)\n```\n")
        + "but it was actually:\n" + ANSIColors.red("```\n\(string)\n```"),
      file: file, line: line)
    return
  }
}

public func assertNoDiagnostics(
  _ diagnostics: DiagnosticSet,
  file: StaticString = #file, line: UInt = #line
) {
  if !diagnostics.isEmpty {
    XCTFail(
      "Expected no diagnostics, but got: \(ANSIColors.red(diagnostics.description))",
      file: file, line: line)
  }
}
