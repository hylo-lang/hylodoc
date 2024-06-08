import DequeModule
import Foundation
import PathWrangler

public struct URLResolver {
  private var references: [AnyTargetID: (RelativePath, AnyTargetID?)] = [:]
  private let baseUrl: AbsolutePath

  public init(baseUrl: AbsolutePath) {
    self.baseUrl = baseUrl
  }

  // Resolve the reference to a target
  public mutating func resolve(target: AnyTargetID, filePath: RelativePath, parent: AnyTargetID?) {
    references[target] = (filePath, parent)
  }

  // Get the file path of the target
  public func pathToFile(target: AnyTargetID) -> URL? {
    guard let targetRef = references[target]?.0 else {
      return nil
    }

    return URL(path: targetRef.absolute(in: baseUrl))
  }

  // Get the relative path of the target to the root
  public func pathToRoot(target: AnyTargetID) -> RelativePath? {
    guard let targetRef = references[target]?.0 else {
      return nil
    }

    let depth = targetRef.pathString.filter { $0 == "/" }.count
    return RelativePath(pathString: String(repeating: "../", count: depth))
  }

  // Get a url referencing from one target to another
  public func refer(from: AnyTargetID, to: AnyTargetID) -> RelativePath? {
    if case .empty = from {
      return references[to]?.0
    } else if case .empty = to {
      return nil
    } else if from == to {
      return nil
    }

    guard let fromUrl = references[from]?.0 else {
      return nil
    }

    guard let toUrl = references[to]?.0 else {
      return nil
    }

    return fromUrl.refer(to: toUrl)
  }

  // Get the call stack from a target
  public func pathStack(target: AnyTargetID) -> [AnyTargetID] {
    var stack: [AnyTargetID] = []
    var cursor: AnyTargetID? = target
    while let id = cursor {
      stack.insert(id, at: 0)

      cursor = references[id]?.1
    }

    return stack
  }

}
