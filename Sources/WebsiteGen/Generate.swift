import DocumentationDB
import Foundation
import FrontEnd

/// Protocol responsible for how to store assets and other pages
public protocol Exporter {
  func file(from: URL, to: URL) throws
  func html(content: String, to: URL) throws
  func directory(to: URL) throws
}

/// Render and export an arbitrary asset page
///
/// - Precondition: assets should be breath or deapth first so all parent directories already exist
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: asset to render page of
///   - with: exporter, used to handle file writes and directory creation
public func generateAsset(ctx: GenerationContext, of: AnyAssetID, with exporter: Exporter) throws {
  guard let target = ctx.urlResolver.pathToFile(target: .asset(of)) else {
    //TODO throw exception
    return
  }

  // Handle other file
  if case .otherFile(let id) = of {
    // Copy file to target
    let otherFile = ctx.documentation.assets.otherFiles[id]!
    try exporter.file(from: otherFile.location, to: target)
    return
  } else if case .folder(_) = of {
    try exporter.directory(to: target.deletingLastPathComponent())
  }

  // Render and export page
  let content = try renderAssetPage(ctx: ctx, of: of)
  try exporter.html(content: content, to: target)
}

/// Render and export an arbitrary symbol page
///
/// - Parameters:
///   - ctx: context for page generation, containing documentation database, ast and stencil templating
///   - of: symbol to render page of
public func generateSymbol(ctx: GenerationContext, of: AnyDeclID, with: Exporter) throws {
  guard let target = ctx.urlResolver.pathToFile(target: .symbol(of)) else {
    //TODO throw exception
    return
  }

  // Render and export page
  let content = try renderSymbolPage(ctx: ctx, of: of)
  try with.html(content: content, to: target)
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
