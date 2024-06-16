import Foundation

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
  func file(from: URL, to: URL) throws
  func html(content: String, to: URL) throws
  func directory(to: URL) throws
}

public struct DefaultExporter: Exporter {
  public func file(from: URL, to: URL) throws {
    // Copy file
    try FileManager.default.createDirectory(
      at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: from, to: to)
  }

  public func html(content: String, to: URL) throws {
    // Write file
    try FileManager.default.createDirectory(
      at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
    try content.write(to: to, atomically: false, encoding: String.Encoding.utf8)
  }

  public func directory(to: URL) throws {
    // Create directory and parents
    try FileManager.default.createDirectory(at: to, withIntermediateDirectories: true)
  }
}
