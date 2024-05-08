import XCTest

@testable import DocExtractor

final class DealerTests: XCTestCase {
  func testIsEven() {
    let result = isEven(number: 2)
    XCTAssertTrue(result)
  }
}
