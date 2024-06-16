import DocumentationDB

extension DocumentationID<OtherLocalFileAsset> {
  public init?(_ targetId: AnyTargetID) {
    guard case .asset(let assetId) = targetId else {
      return nil
    }

    guard case .otherFile(let otherFileId) = assetId else {
      return nil
    }

    self = otherFileId
  }
}

/// Check if the target is of type "other" since these should be excluded from regular resolution
func isOtherTarget(_ targetId: AnyTargetID) -> Bool {
  let otherFileId: OtherLocalFileAsset.ID? = DocumentationID.init(targetId)
  return otherFileId != nil
}

func resolveOtherTarget(
  _ documentationDatabase: DocumentationDatabase, _ targetResolver: TargetResolver,
  targetId: AnyTargetID, parentId: AnyTargetID?
) -> OtherResolvedTarget {
  guard let otherFileId: OtherLocalFileAsset.ID = DocumentationID.init(targetId) else {
    fatalError("unexpected target " + String(describing: targetId))
  }

  let otherFile = documentationDatabase.assets[otherFileId]!
  let relativePath = relativePathToParent(
    targetResolver,
    of: parentId,
    with: otherFile.name
  )

  return OtherResolvedTarget(
    sourceUrl: otherFile.location,
    relativePath: relativePath
  )
}
