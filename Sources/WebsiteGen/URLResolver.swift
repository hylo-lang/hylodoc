import DequeModule
import Foundation
import OrderedCollections
import PathWrangler

public struct URLResolver {
  var tree: Tree? = nil
  var references: OrderedDictionary<AnyTargetID, (path: RelativePath, parentId: AnyTargetID?)> = [:]
  let baseUrl: AbsolutePath

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
    // same target
    if from == to {
      return nil
    }

    // what is being referred to
    guard let toUrl = references[to]?.path else {
      return nil
    }

    // where are we referring from
    guard let fromUrl = references[from]?.path else {
      // refer from root if we got nothing to refer from
      return RelativePath(pathString: "").refer(to: toUrl)
    }

    return fromUrl.refer(to: toUrl)
  }

  // Get the call stack from a target
  public func pathStack(target: AnyTargetID) -> [AnyTargetID] {
    var stack: [AnyTargetID] = []
    var cursor: AnyTargetID? = target
    while let id = cursor {
      stack.insert(id, at: 0)

      cursor = references[id]?.parentId
    }

    return stack
  }

  /// Generate the navigation tree
  public mutating func computeTree(ctx: GenerationContext) {
    // Map references into tree items
    var treeItems = ctx.urlResolver.references.filter {
      // Don't include other-files in navigation
      switch $0.key {
      case .asset(let assetId):
        switch assetId {
        case .otherFile(_):
          return false
        default:
          return true
        }
      default:
        return true
      }
    }.reduce(into: OrderedDictionary<AnyTargetID, TreeDynamicItem>()) {
      dict, elem in
      let (key, value) = elem
      dict[key] = TreeDynamicItem(
        parent: value.parentId,
        name: navigationNameOfTarget(ctx: ctx, target: key),
        relativePath: value.path,
        children: []
      )
    }.filter { !$0.value.name.isEmpty }

    // Apply nesting
    var roots: [AnyTargetID] = []
    for (target, item) in treeItems {
      guard let parentId = item.parent else {
        // If it has no parent then it must be a root
        roots.append(target)
        continue
      }

      // Make item a child
      treeItems[parentId]!.children.append(target)
    }

    // Flatten tree from root items
    self.tree = roots.map { id in flatItem(ctx: ctx, treeItems: treeItems, targetId: id) }
  }

}
