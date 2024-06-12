import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import Stencil

public struct GenerationContext {
  public let documentation: DocumentationDatabase
  public let stencil: Environment
  public let typedProgram: TypedProgram
  public var urlResolver: URLResolver
  public let htmlGenerator: HtmlGenerator
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
) -> Bool {
  // Setup Context
  let stencil = createDefaultStencilEnvironment()
  let resolver = URLResolver(baseUrl: AbsolutePath(url: target)!)
  var ctx = GenerationContext(
    documentation: documentation,
    stencil: stencil,
    typedProgram: typedProgram,
    urlResolver: resolver,
    htmlGenerator: RenderHTMLGenerator()
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
  
  let assetsExportLocation = URL(fileURLWithPath: "assets", relativeTo: target)
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
  ctx: GenerationContext, exporter: Exporter, target: URL
) {
  var env: [String: Any] = [:]

  env["pathToRoot"] = "."
  env["pageType"] = "Folder"
  env["breadcrumb"] = []

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

  env["toc"] = tableOfContents(stencilContext: env)
  let content = try! ctx.stencil.renderTemplate(name: "folder_layout.html", context: env)
  try! exporter.html(content: content, to: URL(fileURLWithPath: "index.html", relativeTo: target))
}
