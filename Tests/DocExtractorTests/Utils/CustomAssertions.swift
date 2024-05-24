import XCTest

func assertContains(
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
func assertNotContains(
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
