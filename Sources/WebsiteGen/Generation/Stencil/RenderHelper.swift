import DocumentationDB
import Foundation
import FrontEnd
import PathWrangler
import Stencil

public typealias StencilContext = (templateName: String, context: [String: Any])

/// Extension to the Stencil Environment struct to allow for default behavior of whitespace control and custom filters
/// Removes whitespace before a block and whitespace and a single newline after a block
/// Other trim options can be found at: https://github.com/stencilproject/Stencil/blob/master/Sources/Stencil/TrimBehaviour.swift
extension Environment {
  public init(loader: Loader?) {
    let ext = Extension()
    ext.registerFilter("convertToID") { (value: Any?) in return convertToID(value) }
    ext.registerFilter("toString") { value in String(describing: value) }
    ext.registerTag("refer", parser: ReferNode.parse)

    self.init(
      loader: loader,
      extensions: [ext],
      trimBehaviour: .smart
    )
  }
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

/// Convert a string to lowercase words separated by hyphens
/// - Parameter value: the string to convert
/// - Returns: the converted string, or the original value if it is not a string
func convertToID(_ value: Any?) -> Any? {
  guard let string = value as? String else { return value }

  // taken from Tests/WebsiteGenTests/TableOfContentsHelperTest/TableOfContentsHelperTest.swift
  return string.prefix(1).lowercased() + string.dropFirst().replacingOccurrences(of: " ", with: "")
}

/// Render a page with the render and stencil context for a target
public func renderPage(
  _ render: inout GenerationContext, _ stencil: StencilContext, of targetId: AnyTargetID
) throws -> String {
  var completeContext: [String: Any] = stencil.context
  let target = render.documentation.targetResolver[targetId]
  completeContext["target"] = target
  completeContext["breadcrumb"] = render.breadcrumb
  completeContext["toc"] = tableOfContents(stencilContext: stencil.context)
  completeContext["pathToRoot"] = target?.relativePath.pathToRoot ?? RelativePath.current
  //TODO Tree navigation

  return try render.stencilEnvironment.renderTemplate(
    name: stencil.templateName, context: completeContext)
}
