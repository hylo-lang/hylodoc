import Foundation
import Stencil

/// Refer tag to refer between relative paths
class PathNode: NodeType {
  let resolvable: Resolvable
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let components = token.components
    if components.count != 2 {
      throw TemplateSyntaxError("'path' tag should have the format: `path <url>`.")
    }

    let resolvable = try parser.compileResolvable(components[1], containedIn: token)

    return PathNode(
      resolvable: resolvable,
      token: token
    )
  }

  init(resolvable: Resolvable, token: Token?) {
    self.resolvable = resolvable
    self.token = token
  }

  // Render the reference between two RelativePaths
  func render(_ context: Context) throws -> String {
    let url = try resolve(context, resolvable)

    return urlToEncodedPath(url)
  }

  // Resolve Resolvable from Context into an optional RelativePath
  private func resolve(_ context: Context, _ resolvable: Resolvable) throws -> URL {
    let resolved = try resolvable.resolve(context)

    if let url = resolved as? URL {
      return url
    }

    throw RuntimeError("unexpected value: " + String(describing: resolved))
  }
}

/// From https://stackoverflow.com/a/45833131
struct RuntimeError: LocalizedError {
  let description: String

  init(_ description: String) {
    self.description = description
  }

  var errorDescription: String? {
    description
  }
}

public func urlToEncodedPath(_ url: URL) -> String {
  precondition(!url.path.contains(":"), "we should not generate URLs containing the colon character")
  return url.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "."
}
