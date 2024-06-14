import DocExtractor
import DocumentationDB
import Foundation
import FrontEnd
import StandardLibraryCore
import Stencil
import WebsiteGen
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class AssociatedTypeTest: XCTestCase {
  func test() throws {
    try runFullPipelineWithoutErrors(
      at: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("TestModule"))
  }
}
