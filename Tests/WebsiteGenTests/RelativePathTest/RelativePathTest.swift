import PathWrangler
import XCTest

@testable import WebsiteGen

final class RelativePathTest: XCTestCase {
  func testSimilarPathPrefix() {
    let target1: RelativePath = RelativePath(pathString: "path/to/some/other/target.html")
    let target2: RelativePath = RelativePath(pathString: "path/article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "../../../article.html")
    )
    XCTAssertEqual(
      target2.refer(to: target1),
      RelativePath(pathString: "to/some/other/target.html")
    )
  }

  func testDifferentPathPrefix() {
    let target1: RelativePath = RelativePath(pathString: "a/path/to/some/other/target.html")
    let target2: RelativePath = RelativePath(pathString: "some/path/article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "../../../../../some/path/article.html")
    )
    assertReferEqual(
      target2,
      target1,
      RelativePath(pathString: "../../a/path/to/some/other/target.html")
    )
  }

  func testNoParentPath() {
    let target1: RelativePath = RelativePath(pathString: "target.html")
    let target2: RelativePath = RelativePath(pathString: "article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "article.html")
    )
    assertReferEqual(
      target2,
      target1,
      RelativePath(pathString: "target.html")
    )
  }

  func testSameParentPath() {
    let target1: RelativePath = RelativePath(pathString: "some/path/target.html")
    let target2: RelativePath = RelativePath(pathString: "some/path/article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "article.html")
    )
    assertReferEqual(
      target2,
      target1,
      RelativePath(pathString: "target.html")
    )
  }

  func testPathWithIndexSameParent() {
    let target1: RelativePath = RelativePath(pathString: "some/path/index.html")
    let target2: RelativePath = RelativePath(pathString: "some/path/article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "article.html")
    )
    assertReferEqual(
      target2,
      target1,
      RelativePath(pathString: ".")
    )
  }

  func testPathWithIndexDifferentParent() {
    let target1: RelativePath = RelativePath(pathString: "some/path/index.html")
    let target2: RelativePath = RelativePath(pathString: "some/other/path/article.html")

    assertReferEqual(
      target1,
      target2,
      RelativePath(pathString: "../other/path/article.html")
    )
    assertReferEqual(
      target2,
      target1,
      RelativePath(pathString: "../../path/")
    )
  }

  func testPathToRootOfDirectory() {
    assertEqual(
      RelativePath(pathString: "some/path/to/directory/").pathToRoot,
      RelativePath(pathString: "../../../../")
    )
  }

  func testPathToRootOfFile() {
    assertEqual(
      RelativePath(pathString: "some/path/to/directory/index.html").pathToRoot,
      RelativePath(pathString: "../../../../")
    )
  }

  func assertReferEqual(_ from: RelativePath, _ to: RelativePath, _ expected: RelativePath) {
    let refer = from.refer(to: to)
    XCTAssertEqual(refer.pathString, expected.pathString)
  }

  func assertEqual(_ relativePath: RelativePath, _ expected: RelativePath) {
    XCTAssertEqual(relativePath.pathString, expected.pathString)
  }

}
