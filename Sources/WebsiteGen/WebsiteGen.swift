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
  target: URL
) {
  // Setup Context
  let stencil = createDefaultStencilEnvironment()
  let resolver = URLResolver(baseUrl: AbsolutePath(url: target)!)
  var ctx = GenerationContext(
    documentation: documentation,
    stencil: stencil,
    typedProgram: typedProgram,
    urlResolver: resolver
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
        case .empty:
          break
        }
      })
  }

  // Generate index page with all the modules
  generateModuleIndexDocumentation(ctx: ctx, exporter: exporter, target: target)

  // Copy public website assets
  // assuming target directory exists already
  let assetsSourceLocation = Bundle.module.bundleURL.appendingPathComponent("Resources")
    .appendingPathComponent("assets")
  try! FileManager.default.copyItem(
    at: assetsSourceLocation,
    to: URL(fileURLWithPath: "assets", relativeTo: target)
  )
}

public func generateModuleIndexDocumentation(
  ctx: GenerationContext, exporter: Exporter, target: URL
) {
  var arr: [String: Any] = [:]

  arr["pathToRoot"] = "."
  arr["pageType"] = "Folder"
  arr["breadcrumb"] = []

  // check if folder has documentation
  arr["pageTitle"] = "Documentation"
  arr["name"] = arr["pageTitle"]

  arr["children"] = ctx.documentation.modules.map {
    module in
    (
      getAssetTitle(.folder(module.rootFolder), ctx.documentation.assets),
      ctx.urlResolver.refer(from: .empty, to: .asset(.folder(module.rootFolder)))
    )
  }

  let content = try! ctx.stencil.renderTemplate(name: "folder_layout.html", context: arr)
  try! exporter.html(content: content, to: URL(fileURLWithPath: "index.html", relativeTo: target))
}
