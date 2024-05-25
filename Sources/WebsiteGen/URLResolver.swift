import Foundation
import PathWrangler

public struct URLResolver {
  private var references: [AnyTargetID: RelativePath] = [:]
  private let baseUrl: AbsolutePath

  public init(baseUrl: AbsolutePath) {
    self.baseUrl = baseUrl
  }

  // Resolve the reference to a target
  public mutating func resolve(target: AnyTargetID, filePath: RelativePath) {
    references[target] = filePath
  }

  // Get the file path of the target
  public func pathToFile(target: AnyTargetID) -> URL {
    return URL(path: references[target]!.absolute(in: baseUrl))
  }

  // Get the relative path of the target to the root
  public func pathToRoot(target: AnyTargetID) -> RelativePath {
    let depth = references[target]!.pathString.filter { $0 == "/" }.count
    return RelativePath(pathString: String(repeating: "../", count: depth))
  }

  // Get a url referencing from one target to another
  public func refer(from: AnyTargetID, to: AnyTargetID) -> RelativePath {
    let fromUrl = references[from]!
    let toUrl = references[to]!

    return fromUrl.refer(to: toUrl)
  }

}

public struct URLResolvingVisitor: DocumentationVisitor {
  private var urlResolver: URLResolver

  public init(urlResolver: inout URLResolver) {
    self.urlResolver = urlResolver
  }

  public mutating func visit(path: TargetPath) {
    urlResolver.resolve(target: path.target(), filePath: path.url)
  }
}
