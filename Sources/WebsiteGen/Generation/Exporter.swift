import Foundation
import PathWrangler

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
  func copyFromFile(from: URL, to: RelativePath) throws
  func exportHtml(_ content: String, at: RelativePath) throws
  func createDirectory(at: RelativePath) throws
}

public struct DefaultExporter: Exporter {
  let absolute: AbsolutePath

  public init(_ absolute: AbsolutePath) {
    self.absolute = absolute
  }

  public func relativeToUrl(_ path: RelativePath) -> URL {
    return URL(path: path.absolute(in: absolute).resolved())
  }

  public func copyFromFile(from: URL, to: RelativePath) throws {
    // Create parent directories
    try createDirectory(at: to / "..")

    // Copy file
    let url = relativeToUrl(to)
    try FileManager.default.copyItem(at: from, to: url)
  }

  public func exportHtml(_ content: String, at: RelativePath) throws {
    // Create parent directories
    try createDirectory(at: at / "..")

    // Write to file
    let url = relativeToUrl(at)
    try content.write(to: url, atomically: false, encoding: String.Encoding.utf8)
  }

  /// Create directory and its parents
  public func createDirectory(at: RelativePath) throws {
    let url = relativeToUrl(at)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
}
