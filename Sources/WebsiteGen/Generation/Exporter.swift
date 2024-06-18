import Foundation

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
  func copyFromFile(from: URL, to: URL) throws
  func exportHtml(_ content: String, at: URL) throws
  func createDirectory(at: URL) throws
}

/// Default exporter where all target URL's see the export directory as root
public struct DefaultExporter: Exporter {
  let baseUrl: URL

  public init(_ baseUrl: URL) {
    self.baseUrl = baseUrl
  }

  public func relativeToUrl(_ url: URL) -> URL {
    return baseUrl.appendingPathComponent(url.path)
  }

  public func copyFromFile(from: URL, to: URL) throws {
    // Create parent directories
    try createDirectory(at: to.deletingLastPathComponent())

    // Copy file
    let url = relativeToUrl(to)
    try FileManager.default.copyItem(at: from, to: url)
  }

  public func exportHtml(_ content: String, at: URL) throws {
    // Create parent directories
    try createDirectory(at: at.deletingLastPathComponent())

    // Write to file
    let url = relativeToUrl(at)
    try content.write(to: url, atomically: false, encoding: String.Encoding.utf8)
  }

  /// Create directory and its parents
  public func createDirectory(at: URL) throws {
    let url = relativeToUrl(at)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
}
