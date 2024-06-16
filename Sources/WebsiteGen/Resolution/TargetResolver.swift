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
  let parent: AnyTargetID?
  let simpleName: String
  let navigationName: String
  let children: [AnyTargetID]
  let relativePath: RelativePath

  public init(
    parent: AnyTargetID?, simpleName: String, navigationName: String, children: [AnyTargetID],
    relativePath: RelativePath
  ) {
    self.parent = parent
    self.simpleName = simpleName
    self.navigationName = navigationName
    self.children = children
    self.relativePath = relativePath
  }
}

public struct OtherResolvedTarget {
  let sourceUrl: URL
  let relativePath: RelativePath

  public init(sourceUrl: URL, relativePath: RelativePath) {
    self.sourceUrl = sourceUrl
    self.relativePath = relativePath
  }
}

public struct TargetResolver {
  public var otherTargets: [AnyTargetID: OtherResolvedTarget] = [:]
  public var targets: [AnyTargetID: ResolvedTarget] = [:]
  public var rootTargets: [AnyTargetID] = []

  /// Get the resolved target of a target identity
  public subscript(_ targetId: AnyTargetID?) -> ResolvedTarget? {
    if targetId == nil {
      return nil
    }

    return targets[targetId!]
  }

  /// Get the navigation item of a target identity
  public subscript(navigation targetId: AnyTargetID?) -> NavigationItem? {
    if targetId == nil {
      return nil
    }

    guard let resolved = targets[targetId!] else {
      return nil
    }

    return NavigationItem(
      name: resolved.navigationName,
      relativePath: resolved.relativePath,
      typeClass: classOfTarget(targetId!),
      children: resolved.children
    )
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
  public mutating func resolveOther(targetId: AnyTargetID, _ resolved: OtherResolvedTarget) {
    otherTargets[targetId] = resolved
  }

  /// Get a url referencing from one target to another
  public func refer(from: AnyTargetID, to: AnyTargetID) -> RelativePath? {
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
}
