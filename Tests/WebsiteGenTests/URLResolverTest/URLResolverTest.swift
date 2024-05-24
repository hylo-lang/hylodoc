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
    resolver.resolve(target: targetId, filePath: RelativePath(pathString: "path/to/target.html"))

    XCTAssertEqual(
      resolver.pathToFile(target: targetId), URL(fileURLWithPath: "/root/path/to/target.html"))
  }

  func testRootPath() {
    let targetId: AnyTargetID = .asset(.folder(FolderAsset.ID(1)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: targetId, filePath: RelativePath(pathString: "path/to/some/other/target.html"))

    XCTAssertEqual(
      resolver.pathToRoot(target: targetId),
      RelativePath(pathString: String.init(repeating: "../", count: 4)))
  }

  func testReferenceSimilar() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))
    let target2: AnyTargetID = .asset(.article(ArticleAsset.ID(2)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: target1, filePath: RelativePath(pathString: "path/to/some/other/target.html"))
    resolver.resolve(target: target2, filePath: RelativePath(pathString: "path/article.html"))

    XCTAssertEqual(
      resolver.refer(from: target1, to: target2), RelativePath(pathString: "../../../article.html"))
    XCTAssertEqual(
      resolver.refer(from: target2, to: target1),
      RelativePath(pathString: "to/some/other/target.html"))
  }

  func testReferenceNotSimilar() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))
    let target2: AnyTargetID = .asset(.article(ArticleAsset.ID(2)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(
      target: target1, filePath: RelativePath(pathString: "a/path/to/some/other/target.html"))
    resolver.resolve(target: target2, filePath: RelativePath(pathString: "some/path/article.html"))

    XCTAssertEqual(
      resolver.refer(from: target1, to: target2),
      RelativePath(pathString: "../../../../../some/path/article.html"))
    XCTAssertEqual(
      resolver.refer(from: target2, to: target1),
      RelativePath(pathString: "../../a/path/to/some/other/target.html"))
  }

  func testReferenceSameParent() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))
    let target2: AnyTargetID = .asset(.article(ArticleAsset.ID(2)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(target: target1, filePath: RelativePath(pathString: "target.html"))
    resolver.resolve(target: target2, filePath: RelativePath(pathString: "article.html"))

    XCTAssertEqual(
      resolver.refer(from: target1, to: target2), RelativePath(pathString: "article.html"))
    XCTAssertEqual(
      resolver.refer(from: target2, to: target1), RelativePath(pathString: "target.html"))
  }

  func testReferenceSameParentNested() {
    let target1: AnyTargetID = .asset(.article(ArticleAsset.ID(1)))
    let target2: AnyTargetID = .asset(.article(ArticleAsset.ID(2)))

    var resolver: URLResolver = .init(baseUrl: AbsolutePath(pathString: "/root"))
    resolver.resolve(target: target1, filePath: RelativePath(pathString: "some/path/target.html"))
    resolver.resolve(target: target2, filePath: RelativePath(pathString: "some/path/article.html"))

    XCTAssertEqual(
      resolver.refer(from: target1, to: target2), RelativePath(pathString: "article.html"))
    XCTAssertEqual(
      resolver.refer(from: target2, to: target1), RelativePath(pathString: "target.html"))
  }
}
