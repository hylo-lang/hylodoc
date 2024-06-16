import Foundation
import PathWrangler

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
  func file(from: URL, to: RelativePath) throws
  func html(_ content: String, at: RelativePath) throws
  func directory(at: RelativePath) throws
}

public struct DefaultExporter: Exporter {
  let absolute: AbsolutePath

  public init(_ absolute: AbsolutePath) {
    self.absolute = absolute
  }

  public func relativeToUrl(_ path: RelativePath) -> URL {
    return URL(path: path.absolute(in: absolute))
  }

  public func file(from: URL, to: RelativePath) throws {
    let url = relativeToUrl(to)

    // Copy file
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: from, to: url)
  }

  public func html(_ content: String, at: RelativePath) throws {
    let url = relativeToUrl(at)

    // Write file
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try content.write(to: url, atomically: false, encoding: String.Encoding.utf8)
  }

  public func directory(at: RelativePath) throws {
    let url = relativeToUrl(at)

    // Create directory and parents
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
}
