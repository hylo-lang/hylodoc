import XCTest

@testable import WebsiteGen

final class DealerTests: XCTestCase {
  func testIsOdd() {
    let result = isOdd(number: 1)
    XCTAssertTrue(result)
  }
}
