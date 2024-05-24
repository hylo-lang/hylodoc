import Stencil
import XCTest

@testable import WebsiteGen

final class StencilBundleTest: XCTestCase {
  func test() {
    let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))

    XCTAssertNoThrow(try stencil.renderTemplate(name: "index.html", context: ["name": "Test"]))
  }
}
