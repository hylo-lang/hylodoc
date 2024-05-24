import DocumentationDB
import Foundation
import FrontEnd
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
///   - db: documentation database
///   - ast: abstract syntax tree
///   - rootModule: the identity of the root module
public func generateDocumentation(
  documentation: DocumentationDatabase, typedProgram: TypedProgram, target: URL
) {
  // Setup Context
  let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))
  var ctx = GenerationContext(
    documentation: documentation,
    stencil: stencil,
    typedProgram: typedProgram,
    urlResolver: URLResolver()
  )

  // Resolve URL's
  var resolvingVisitor: DocumentationVisitor = URLResolvingVisitor(urlResolver: &ctx.urlResolver)
  documentation.modules.forEach {
    module in traverse(ctx: ctx, root: .folder(module.rootFolder), visitor: &resolvingVisitor)
  }

  // Generate assets and symbols
  struct GeneratingVisitor: DocumentationVisitor {
    private let ctx: GenerationContext
    private let exporter: Exporter

    public init(ctx: GenerationContext, exporter: Exporter) {
      self.ctx = ctx
      self.exporter = exporter
    }

    public mutating func visit(path: TargetPath) {
      do {
        switch path.target() {
        case .asset(let id):
          try generateAsset(ctx: ctx, of: id, with: exporter)
        case .symbol(let id):
          try generateSymbol(ctx: ctx, of: id, with: exporter)
        }
      } catch (let error) {
        print(error)
      }
    }
  }
  var generatingVisitor: DocumentationVisitor = GeneratingVisitor(
    ctx: ctx, exporter: DefaultExporter())
  documentation.modules.forEach {
    module in traverse(ctx: ctx, root: .folder(module.rootFolder), visitor: &generatingVisitor)
  }

  // Copy assets to target
}
