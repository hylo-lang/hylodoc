import Foundation
import FrontEnd
import TestUtils
import XCTest

@testable import HDCUtils

final class HDCDiagnosticSetTests: XCTestCase {

  let dummyRange = SourceRange(
    Range(uncheckedBounds: (lower: "".startIndex, upper: "".endIndex)),
    in: SourceFile(
      synthesizedText: """
          value foo
        """)
  )

  struct TestDiagnostic: HDCDiagnostic {
    public let level: HDCDiagnosticLevel
    public let message: String
    public let site: SourceRange
    public let notes: [AnyHashable]

    public init(
      level: HDCDiagnosticLevel, message: String, site: SourceRange, notes: [AnyHashable] = []
    ) {
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
    }
  }

  func testEmptyDiagnosticSet() {
    let diagnosticSet = HDCDiagnosticSet()

    XCTAssert(diagnosticSet.isEmpty)
  }

  func testErrorInSet() {
    var diagnosticSet = HDCDiagnosticSet()

    diagnosticSet.insert(
      TestDiagnostic.error("myTestError", at: dummyRange)
    )

    XCTAssert(diagnosticSet.containsError)
    assertContains(diagnosticSet.description, what: "myTestError")
  }

  func testWarningButNoErrors() {
    var diagnosticSet = HDCDiagnosticSet()

    diagnosticSet.insert(
      TestDiagnostic.warning("myTestError", at: dummyRange)
    )

    XCTAssert(!diagnosticSet.containsError)
    assertContains(diagnosticSet.description, what: "myTestError")
  }

}
