import DocumentationDB
import Foundation
import FrontEnd
import MarkdownKit
import PathWrangler
import Stencil

/// Context containing all the documentation used in the Website Generation phase
public struct DocumentationContext {
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
  let context = DocumentationContext(
    documentation: documentation,
    typedProgram: typedProgram,
    targetResolver: resolveTargets(
      documentationDatabase: documentation,
      typedProgram: typedProgram
    )
  )

  // Initialize exporter
  let exporter: DefaultExporter = .init(AbsolutePath(url: exportPath)!)

  do {
    // Generate content
    try generateIndexAndTargetPages(
      documentation: context,
      exporter: exporter
    )

    // Export other targets
    try context.targetResolver.otherTargets.forEach {
      try exporter.file(
        from: $0.value.sourceUrl,
        to: $0.value.relativePath
      )
    }
  } catch {
    print("Error while generating website content")
    print(error)
  }

  return copyPublicWebsiteAssets(exporter: exporter)
}

/// Precondition: directory exists at `exportPath`
func copyPublicWebsiteAssets(exporter: Exporter) -> Bool {
  let assetsSourceLocation = Bundle.module.bundleURL
    .appendingPathComponent("Resources")
    .appendingPathComponent("assets")

  do {
    try exporter.file(from: assetsSourceLocation, to: RelativePath(pathString: "assets"))
  } catch {
    print("Error while copying website assets")
    print("from \"\(assetsSourceLocation)\"")
    print(error)
    return false
  }
  return true
}
