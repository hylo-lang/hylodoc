import DocumentationDB
import Foundation
import FrontEnd
import PathWrangler

public enum AnyTargetID: Equatable, Hashable {
  case asset(AnyAssetID)
  case decl(AnyDeclID)
  case empty
}

public struct ResolvedTarget {
  let id: AnyTargetID
  let parent: AnyTargetID?
  let simpleName: String  // name as seen in the breadcrumb and page title, without additional styling/tags
  let navigationName: String  // name as seen in the tree navigation, which has highlighting of some sort
  let children: [AnyTargetID]
  let relativePath: RelativePath

  public init(
    id: AnyTargetID, parent: AnyTargetID?, simpleName: String, navigationName: String,
    children: [AnyTargetID], relativePath: RelativePath
  ) {
    self.id = id
    self.parent = parent
    self.simpleName = simpleName
    self.navigationName = navigationName
    self.children = children
    self.relativePath = relativePath
  }
}

public struct ResolvedDirectlyCopiedAssetTarget {
  let sourceUrl: URL
  let relativePath: RelativePath

  public init(sourceUrl: URL, relativePath: RelativePath) {
    self.sourceUrl = sourceUrl
    self.relativePath = relativePath
  }
}

public struct TargetResolver {
  var otherTargets: [AnyTargetID: ResolvedDirectlyCopiedAssetTarget] = [:]
  var targets: [AnyTargetID: ResolvedTarget] = [:]
  var backReferences: [AnyTargetID: AnyTargetID] = [:]
  public var rootTargets: [AnyTargetID] = []

  /// Get the resolved target of a target identity
  public subscript(_ targetId: AnyTargetID?) -> ResolvedTarget? {
    if targetId == nil {
      return nil
    }

    return targets[targetId!]
  }

  /// Resolve a target by matching its identity with a ResolvedTarget element
  public mutating func resolve(targetId: AnyTargetID, _ resolved: ResolvedTarget) {
    // Resolve target
    targets[targetId] = resolved

    // Check if the target is a root
    if resolved.parent == nil {
      rootTargets.append(targetId)
    }
  }

  /// Resolve any other target with just the relative path as these will just be copied directly
  public mutating func resolveOther(
    targetId: AnyTargetID, _ resolved: ResolvedDirectlyCopiedAssetTarget
  ) {
    otherTargets[targetId] = resolved
  }

  /// Resolve targets referencing back to another target
  public mutating func resolveBackReference(from: AnyTargetID, backTo: AnyTargetID) {
    backReferences[from] = backTo
  }

  /// Get a url referencing from one target to another
  public func refer(from: AnyTargetID, to: AnyTargetID) -> RelativePath? {
    // Resolve back reference
    if let referBack = backReferences[to] {
      print(referBack)
      return refer(from: from, to: referBack)
    }

    // same target
    if from == to {
      return nil
    }

    // what is being referred to
    guard let relativePathTo = targets[to]?.relativePath else {
      return nil
    }

    // where are we referring from
    guard let relativePathFrom = targets[from]?.relativePath else {
      // refer from root if we got nothing to refer from
      return relativePathTo
    }

    return relativePathFrom.refer(to: relativePathTo)
  }

  /// Get the absolute file path of a target in an absolute path
  public func pathToFile(from: AnyTargetID, in absolutePath: AbsolutePath) -> AbsolutePath? {
    guard let relativePath = targets[from]?.relativePath else {
      return nil
    }

    return relativePath.absolute(in: absolutePath)
  }

  public func navigationItemFromTarget(targetId: AnyTargetID) -> NavigationItem? {
    guard let resolved = targets[targetId] else {
      return nil
    }

    return NavigationItem(
      id: targetId,
      name: resolved.navigationName,
      relativePath: resolved.relativePath,
      cssClassOfTarget: getCssClassOfTarget(targetId),
      children: resolved.children.map { navigationItemFromTarget(targetId: $0) }.filter {
        $0 != nil
      }.map { $0! }
    )
  }
}
