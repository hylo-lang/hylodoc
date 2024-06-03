import DocumentationDB
import Foundation
import FrontEnd
import PathWrangler
import Stencil

public struct GenerationContext {
  public let documentation: DocumentationDatabase
  public let stencil: Environment
  public let typedProgram: TypedProgram
  public var urlResolver: URLResolver
}

/// Render the full documentation website
///
/// - Parameters:
///   - documentation: documentation database
///   - typedProgram: typed program
///   - target: directory to export documentation to
public func generateDocumentation(
  documentation: DocumentationDatabase,
  typedProgram: TypedProgram,
  target: URL
) {
  // Setup Context
  let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))
  var ctx = GenerationContext(
    documentation: documentation,
    stencil: stencil,
    typedProgram: typedProgram,
    urlResolver: URLResolver(baseUrl: AbsolutePath(url: target)!)
  )

  // Resolve URL's
  //var resolvingVisitor: DocumentationVisitor = URLResolvingVisitor(urlResolver: &ctx.urlResolver)
  documentation.modules.forEach {
    module in
    traverse(
      ctx: ctx, root: .folder(module.rootFolder),
      visitor: {
        (path: TargetPath) in
        ctx.urlResolver.resolve(target: path.target, filePath: path.url, parent: path.parent)
      })
  }

  // Generate assets and symbols
  let exporter: DefaultExporter = .init()
  documentation.modules.forEach {
    module in
    traverse(
      ctx: ctx, root: .folder(module.rootFolder),
      visitor: {
        (path: TargetPath) in
        switch path.target {
        case .asset(let id):
          try! generateAsset(ctx: ctx, of: id, with: exporter)
        case .symbol(let id):
          try! generateSymbol(ctx: ctx, of: id, with: exporter)
        }
      })
  }

  // Create asset directorty
  let assetDir = URL(fileURLWithPath: "assets", relativeTo: target)
  try! FileManager.default.createDirectory(at: assetDir, withIntermediateDirectories: true)

  // Copy assets (everything but html templates) to asset directory
  let bundledAssets = try! FileManager.default.contentsOfDirectory(
    at: Bundle.module.bundleURL, includingPropertiesForKeys: nil)
  for bundledAsset in bundledAssets {
    if bundledAsset.lastPathComponent.hasSuffix(".html") {
      continue
    }

    try! FileManager.default.copyItem(
      at: bundledAsset,
      to: URL(fileURLWithPath: "assets/" + bundledAsset.lastPathComponent, relativeTo: assetDir))
  }
}
