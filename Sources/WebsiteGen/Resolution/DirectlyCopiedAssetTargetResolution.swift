import DocumentationDB

extension DocumentationID<OtherLocalFileAsset> {
  public init?(_ targetId: AnyTargetID) {
    guard case .asset(let assetId) = targetId, case .otherFile(let otherFileId) = assetId else {
      return nil
    }

    self = otherFileId
  }
}

/// Check if the target is of type "other" since these should be excluded from regular resolution
func isDirectlyCopiedAssetTarget(_ targetId: AnyTargetID) -> Bool {
  let otherFileId: OtherLocalFileAsset.ID? = DocumentationID.init(targetId)
  return otherFileId != nil
}

func resolveDirectlyCopiedAssetTarget(
  _ documentationDatabase: DocumentationDatabase, _ targetResolver: TargetResolver,
  targetId: AnyTargetID, parentId: AnyTargetID?
) -> ResolvedDirectlyCopiedAssetTarget {
  guard let otherFileId: OtherLocalFileAsset.ID = DocumentationID.init(targetId) else {
    fatalError("unexpected target " + String(describing: targetId))
  }

  let otherFile = documentationDatabase.assets[otherFileId]!
  let url = urlRelativeToParent(
    targetResolver,
    of: parentId,
    with: otherFile.name
  )

  return ResolvedDirectlyCopiedAssetTarget(
    sourceUrl: otherFile.location,
    url: url
  )
}
