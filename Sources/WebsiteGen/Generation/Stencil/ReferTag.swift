import Foundation
import PathWrangler
import Stencil

/// Refer tag to refer between relative paths
class ReferNode: NodeType {
  let fromResolvable: Resolvable
  let toResolvable: Resolvable
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let components = token.components
    if components.count != 3 {
      throw TemplateSyntaxError("'refer' tag should have the format: `refer <from> <to>`.")
    }

    let fromResolvable = try parser.compileResolvable(components[1], containedIn: token)
    let toResolvable = try parser.compileResolvable(components[2], containedIn: token)

    return ReferNode(
      fromResolvable: fromResolvable,
      toResolvable: toResolvable,
      token: token
    )
  }

  init(fromResolvable: Resolvable, toResolvable: Resolvable, token: Token?) {
    self.fromResolvable = fromResolvable
    self.toResolvable = toResolvable
    self.token = token
  }

  // Render the reference between two RelativePaths
  func render(_ context: Context) throws -> String {
    let from = try resolve(context, fromResolvable)
    let to = try resolve(context, toResolvable)

    return from.refer(to: to).pathString
  }

  // Resolve Resolvable from Context into an optional RelativePath
  private func resolve(_ context: Context, _ resolvable: Resolvable) throws -> RelativePath {
    let resolved = try resolvable.resolve(context)
    if resolved == nil {
      return RelativePath.current
    }

    if let relativePath = resolved as? RelativePath {
      return relativePath
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
