import XCTest
import Stencil

@testable import WebsiteGen

final class StencilBundleTest: XCTestCase {
    func test() {
        let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));

        XCTAssertEqual(try? stencil.renderTemplate(name: "index.html", context: ["name":"Test"]), "<h1>Test</h1>")
    }
}
