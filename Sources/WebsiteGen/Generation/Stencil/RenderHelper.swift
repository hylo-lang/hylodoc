import DocumentationDB
import Foundation
import FrontEnd
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
    ext.registerTag("path", parser: PathNode.parse)

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
public func convertToID(_ value: Any?) -> Any? {
  guard let string = value as? String else { return value }

  // taken from Tests/WebsiteGenTests/TableOfContentsHelperTest/TableOfContentsHelperTest.swift
  return string.prefix(1).lowercased() + string.dropFirst().replacingOccurrences(of: " ", with: "")
}

/// Render a page with the render and stencil context for a target
public func renderPage(
  _ context: inout GenerationContext, _ stencil: StencilContext, of targetId: AnyTargetID
) throws -> String {
  var completeContext: [String: Any] = stencil.context
  let target = context.documentation.targetResolver[targetId]
  completeContext["target"] = target
  completeContext["metaDescription"] = target?.metaDescription ?? ""
  completeContext["breadcrumbs"] = context.breadcrumb
  completeContext["toc"] = tableOfContents(stencilContext: stencil.context)
  completeContext["tree"] = context.tree

  return try context.stencilEnvironment.renderTemplate(
    name: stencil.templateName,
    context: completeContext
  )
}
