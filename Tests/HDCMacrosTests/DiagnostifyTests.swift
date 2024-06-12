import HDCMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class DiagnostifyMacroTests: XCTestCase {
  private let macros = ["Diagnostify": DiagnostifyMacro.self]

  func testDiagnostifySuccess() {
    assertMacroExpansion(
      """
      @Diagnostify
      public struct TestError {}
      """,
      expandedSource:
        """

        public struct TestError {

          public let level: HDCDiagnosticLevel
          public let message: String
          public let site: SourceRange
          public let notes: [AnyHashable]

          public init(level: HDCDiagnosticLevel, message: String, site: SourceRange, notes: [AnyHashable] = []) {
            self.level = level
            self.message = message
            self.site = site
            self.notes = notes
          }

          public static func note(_ message: String, at site: SourceRange) -> Self {
            Self(level: .note, message: message, site: site)
          }

          public static func error(
            _ message: String, at site: SourceRange, notes: [AnyHashable] = []
          ) -> Self {
            Self(level: .error, message: message, site: site, notes: notes)
          }

          public static func warning(
            _ message: String, at site: SourceRange, notes: [AnyHashable] = []
          ) -> Self {
            Self(level: .warning, message: message, site: site, notes: notes)
          }}

        extension TestError: HDCDiagnostic {
        }
        """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnostifySuccessAlreadyHasInheritance() {
    //I'm pretty sure if anyone tried this it won't even compile
    assertMacroExpansion(
      """
      @Diagnostify
      public struct TestError: HDCDiagnostic {}
      """,
      expandedSource:
        """

        public struct TestError: HDCDiagnostic {

          public let level: HDCDiagnosticLevel
          public let message: String
          public let site: SourceRange
          public let notes: [AnyHashable]

          public init(level: HDCDiagnosticLevel, message: String, site: SourceRange, notes: [AnyHashable] = []) {
            self.level = level
            self.message = message
            self.site = site
            self.notes = notes
          }

          public static func note(_ message: String, at site: SourceRange) -> Self {
            Self(level: .note, message: message, site: site)
          }

          public static func error(
            _ message: String, at site: SourceRange, notes: [AnyHashable] = []
          ) -> Self {
            Self(level: .error, message: message, site: site, notes: notes)
          }

          public static func warning(
            _ message: String, at site: SourceRange, notes: [AnyHashable] = []
          ) -> Self {
            Self(level: .warning, message: message, site: site, notes: notes)
          }}
        """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnostifyFailNotOnStruct() {
    assertMacroExpansion(
      """
      @Diagnostify
      public enum TestError {}
      """,
      expandedSource:
        """

        public enum TestError {}
        """,
      diagnostics: [
        DiagnosticSpec(
          message: "@Diagnostify can only be applied to a struct.", line: 1, column: 1),
        DiagnosticSpec(
          message: "@Diagnostify can only be applied to a struct.", line: 1, column: 1),
      ],
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
}
