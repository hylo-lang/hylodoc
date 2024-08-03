import DocumentationDB
import Foundation
import FrontEnd

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
  let metaDescription: String // a string already escaped from " and & symbols
  let children: [AnyTargetID]
  let url: URL
  let openSourceUrl: URL?

  public init(
    id: AnyTargetID, parent: AnyTargetID?, simpleName: String, navigationName: String,
    metaDescription: String, children: [AnyTargetID], url: URL, openSourceUrl: URL?
  ) {
    self.id = id
    self.parent = parent
    self.simpleName = simpleName
    self.navigationName = navigationName
    self.metaDescription = metaDescription
    self.children = children
    self.url = url
    self.openSourceUrl = openSourceUrl
  }
}

public struct ResolvedDirectlyCopiedAssetTarget {
  let sourceUrl: URL
  let url: URL

  public init(sourceUrl: URL, url: URL) {
    self.sourceUrl = sourceUrl
    self.url = url
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
  public func url(to: AnyTargetID) -> URL? {
    // Resolve back reference
    if let referBack = backReferences[to] {
      return url(to: referBack)
    }

    // Resolve other targets
    if let otherTarget = otherTargets[to] {
      return otherTarget.url
    }

    return targets[to]?.url
  }

  public func navigationItemFromTarget(targetId: AnyTargetID) -> NavigationItem? {
    guard let resolved = targets[targetId] else {
      return nil
    }

    return NavigationItem(
      id: targetId,
      name: resolved.navigationName,
      url: resolved.url,
      cssClassOfTarget: getCssClassOfTarget(targetId),
      openSourceUrl: resolved.openSourceUrl,
      children: resolved.children.map { navigationItemFromTarget(targetId: $0) }.filter {
        $0 != nil
      }.map { $0! }
    )
  }
}
