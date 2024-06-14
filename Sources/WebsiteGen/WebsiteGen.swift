import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import Stencil

public struct GenerationContext {
  public let documentation: DocumentationDatabase
  public var stencil: Environment
  public let typedProgram: TypedProgram
  public var urlResolver: URLResolver
  public let htmlGenerator: some HyloReferenceResolvingGenerator = CustomHTMLGenerator()
  public var tree: [TreeItem]
}

extension FileSystemLoader {
  public convenience init(path: URL) {
    self.init(paths: [.init(path.fileSystemPath)])
  }
}

public func createFileSystemTemplateLoader() -> FileSystemLoader {
  return FileSystemLoader(
    path: Bundle.module.bundleURL.appendingPathComponent("Resources/templates"))
}
public func createDefaultStencilEnvironment() -> Environment {
  return Environment(loader: createFileSystemTemplateLoader())
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
  exportPath: URL
) -> Bool {
  // Setup Context
  let stencil = createDefaultStencilEnvironment()
  let resolver = URLResolver(baseUrl: AbsolutePath(url: exportPath)!)
  var ctx = GenerationContext(
    documentation: documentation,
    stencil: stencil,
    typedProgram: typedProgram,
    urlResolver: resolver,
    tree: []
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
  ctx.tree = documentation.modules.map {
    treeItemFromAsset(ctx: ctx, assetId: .folder($0.rootFolder))
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
          try! generateAsset(ctx: &ctx, of: id, with: exporter)
        case .symbol(let id):
          try! generateSymbol(ctx: &ctx, of: id, with: exporter)
        case .empty:
          break
        }
      })
  }

  // Generate index page with all the modules
  generateModuleIndexDocumentation(ctx: &ctx, exporter: exporter, target: exportPath)

  return copyPublicWebsiteAssets(exportPath: exportPath)
}

/// Precondition: directory exists at `exportPath`
func copyPublicWebsiteAssets(exportPath: URL) -> Bool {
  let assetsSourceLocation = Bundle.module.bundleURL
    .appendingPathComponent("Resources")
    .appendingPathComponent("assets")

  let assetsExportLocation = exportPath.appendingPathComponent("assets")
  do {
    try FileManager.default.copyItem(
      at: assetsSourceLocation,
      to: assetsExportLocation
    )
  } catch {
    print("Error while copying webside assets")
    print("from \"\(assetsSourceLocation)\"")
    print("to \"\(assetsExportLocation)\":")
    print(error)
    return false
  }
  return true
}

public func generateModuleIndexDocumentation(
  ctx: inout GenerationContext, exporter: Exporter, target: URL
) {
  var env: [String: Any] = [:]

  env["pathToRoot"] = "."
  env["pageType"] = "Folder"

  // check if folder has documentation
  env["pageTitle"] = "Documentation"
  env["name"] = env["pageTitle"]

  env["contents"] = ctx.documentation.modules.map {
    module in
    (
      getAssetTitle(.folder(module.rootFolder), ctx.documentation.assets),
      ctx.urlResolver.refer(from: .empty, to: .asset(.folder(module.rootFolder)))
    )
  }

  let content = try! renderTemplate(
    ctx: &ctx, targetId: .empty, name: "folder_layout.html", env: &env)
  try! exporter.html(content: content, to: URL(fileURLWithPath: "index.html", relativeTo: target))
}
