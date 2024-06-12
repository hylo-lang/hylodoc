import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class URLResolverTest: XCTestCase {
  func testBaseUrl() {
    let targetId: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/target.html"), parent: nil)

    XCTAssertEqual(
      resolver.pathToFile(target: targetId), URL(fileURLWithPath: "/root/path/to/target.html"))
  }

  func testRootPath() {
    let targetId: AnyTargetID = .asset(.folder(FolderAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/some/other/target.html"),
      parent: nil)

    XCTAssertEqual(
      resolver.pathToRoot(target: targetId),
      RelativePath(pathString: String.init(repeating: "../", count: 4)))
  }

  func testReferFromEmptyToTarget() {
    let targetId: AnyTargetID = .asset(.folder(FolderAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/some/other/target.html"),
      parent: nil)

    XCTAssertEqual(
      resolver.refer(from: .empty, to: targetId),
      RelativePath(pathString: "path/to/some/other/target.html")
    )
  }

  func testReferFromTargetToEmpty() {
    let targetId: AnyTargetID = .asset(.folder(FolderAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/some/other/target.html"),
      parent: nil)

    XCTAssertEqual(
      resolver.refer(from: targetId, to: .empty),
      nil
    )
  }

  func testReferToSameTarget() {
    let targetId: AnyTargetID = .asset(.folder(FolderAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/some/other/target.html"),
      parent: nil)

    XCTAssertEqual(
      resolver.refer(from: targetId, to: targetId),
      nil
    )
    XCTAssertEqual(
      resolver.refer(from: .empty, to: .empty),
      nil
    )
  }

  func testNoParent() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: target1, filePath: RelativePath(pathString: "some/path/target.html"), parent: nil)

    XCTAssertEqual(
      resolver.pathStack(target: target1), [target1])
  }

  func testParents() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))
    let target2: AnyTargetID = .asset(.folder(FolderAsset.ID(2)))
    let target3: AnyTargetID = .asset(.folder(FolderAsset.ID(3)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: target1, filePath: RelativePath(pathString: "some/path/target.html"), parent: target2)
    resolver.resolve(
      target: target2, filePath: RelativePath(pathString: "some/path/index.html"), parent: target3)
    resolver.resolve(
      target: target3, filePath: RelativePath(pathString: "some/index.html"), parent: nil)

    XCTAssertEqual(
      resolver.pathStack(target: target1), [target3, target2, target1])
  }
}
