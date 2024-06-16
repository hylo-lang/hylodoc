import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import Stencil

public struct ResolvedDocumentation {
  public let documentation: DocumentationDatabase
  public let typedProgram: TypedProgram
  public var targetResolver: TargetResolver
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
  // Resolve documentation
  let resolved = ResolvedDocumentation(
    documentation: documentation,
    typedProgram: typedProgram,
    targetResolver: resolve(
      documentationDatabase: documentation,
      typedProgram: typedProgram
    )
  )

  // Initialize exporter
  let exporter: DefaultExporter = .init()
  let absoluteExportPath = AbsolutePath(url: exportPath)!

  do {
    // Generate content
    try generate(
      resolved: resolved,
      exportPath: absoluteExportPath,
      exporter: exporter
    )

    // Export other targets
    try resolved.targetResolver.otherTargets.forEach {
      try exporter.file(
        from: $0.value.sourceUrl,
        to: URL(path: $0.value.relativePath.absolute(in: absoluteExportPath))
      )
    }
  } catch {
    print("Error while generating website content")
    print(error)
  }

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
    print("Error while copying website assets")
    print("from \"\(assetsSourceLocation)\"")
    print("to \"\(assetsExportLocation)\":")
    print(error)
    return false
  }
  return true
}
