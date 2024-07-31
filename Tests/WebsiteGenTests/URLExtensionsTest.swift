import FrontEnd
import XCTest

@testable import WebsiteGen

final class URLExtensionsTest: XCTestCase {
  func testAddingAnchor() {
    let url = URL(string: "https://github.com")!.addingAnchor(anchor: "sectionName")
    XCTAssertEqual("https://github.com#sectionName", url?.description)
  }
  func testAddingEmptyAnchor() {
    let url = URL(string: "https://github.com#")!.addingAnchor(anchor: "")
    XCTAssertEqual("https://github.com#", url?.description)
  }

  func testRelativeInwardsPath() throws {
    let relativeOpt = URL(string: "C:/Users/JohnDoe/Documents/Me")!
      .relativeInwardsPath(from: URL(string: "C:/Users/JohnDoe")!)

    let relative = try XCTUnwrap(relativeOpt)
    XCTAssertEqual(["Documents", "Me"], relative)
  }
  func testRelativeInwardsPathEqual() throws {
    let relativeOpt = URL(string: "C:/Users/JohnDoe/")!
      .relativeInwardsPath(from: URL(string: "C:/Users/JohnDoe")!)

    let relative = try XCTUnwrap(relativeOpt)
    XCTAssertEqual([], relative)
  }
  func testRelativeInwardsPathOutside() throws {
    let relativeOpt = URL(string: "C:/Users/")!
      .relativeInwardsPath(from: URL(string: "C:/Users/JohnDoe")!)

    XCTAssertNil(relativeOpt)
  }

  func testAppendingPathComponents() {
    let url = URL(string: "https://github.com")!
      .appendingPathComponents(["user", "repo", "file.html"])

    XCTAssertEqual("https://github.com/user/repo/file.html", url.description)
  }

  func testOpenSourceUrlGeneration() {
    let repoBase = URL(
      string: "https://github.com/hylo-lang/hylo/tree/main/StandardLibrary/Sources")!

    let moduleSource = AST.standardLibraryModulePath
    let fileUrl = moduleSource.appendingPathComponent("Core/BitCast.hylo")

    let url = getOpenSourceUrl(
      repositoryRoot: repoBase,
      moduleSourceRoot: moduleSource,
      sourceLocation: fileUrl,
      site: .init(start: (1, 5), end: (6, 10))
    )

    XCTAssertEqual(
      "https://github.com/hylo-lang/hylo/tree/main/StandardLibrary/Sources/Core/BitCast.hylo#L1C5-L6C10",
      url.description
    )
  }

  func testOpenSourceUrlGenerationNoLine() {
    let repoBase = URL(
      string: "https://github.com/hylo-lang/hylo/tree/main/StandardLibrary/Sources")!

    let moduleSource = AST.standardLibraryModulePath
    let fileUrl = moduleSource.appendingPathComponent("Core/BitCast.hylo")

    let url = getOpenSourceUrl(
      repositoryRoot: repoBase,
      moduleSourceRoot: moduleSource,
      sourceLocation: fileUrl,
      site: nil
    )

    XCTAssertEqual(
      "https://github.com/hylo-lang/hylo/tree/main/StandardLibrary/Sources/Core/BitCast.hylo",
      url.description
    )
  }
}
