import DequeModule
import DocumentationDB
import FrontEnd
import PathWrangler

typealias TargetItem = (parentId: AnyTargetID?, targetId: AnyTargetID)

public func resolve(documentationDatabase: DocumentationDatabase, typedProgram: TypedProgram)
  -> TargetResolver
{
  // Figure out the root targets
  var rootItems: [TargetItem]
  if documentationDatabase.modules.count > 1 {
    // Modules make up the root
    rootItems = documentationDatabase.modules.map {
      TargetItem(
        parentId: nil,
        targetId: .asset(.folder($0.rootFolder))
      )
    }
  } else {
    // Content of the only module makes up the root
    let module: ModuleInfo = documentationDatabase.modules.first { $0 }!
    let folder: FolderAsset = documentationDatabase.assets[module.rootFolder]!
    rootItems = folder.children.map {
      TargetItem(
        parentId: nil,
        targetId: .asset($0)
      )
    }
  }

  // Initialize queue with the root items
  var queue: Deque<TargetItem> = Deque(rootItems)

  // Traverse until every target has been visited
  var targetResolver = TargetResolver()
  while !queue.isEmpty {
    let targetItem = queue.popLast()!

    // Resolve only the path to an asset of type "other file" as they don't show up anywhere else
    if let otherFileId = otherFile(targetItem.targetId) {
      let otherFile = documentationDatabase.assets[otherFileId]!
      let relativePath = relativePathToParent(
        targetResolver, of: targetItem.parentId, with: otherFile.name)
      targetResolver.resolveOther(
        targetId: targetItem.targetId,
        OtherResolvedTarget(
          sourceUrl: otherFile.location,
          relativePath: relativePath
        )
      )
      continue
    }

    // Partially resolve target
    let partialResolvedTarget = resolveTargetPartial(
      documentationDatabase, typedProgram, targetId: targetItem.targetId
    )

    // Get relative path to the target
    let relativePath = relativePathToParent(
      targetResolver, of: targetItem.parentId, with: partialResolvedTarget.pathName)

    // Get the children of the target
    for childId in partialResolvedTarget.children {
      queue.append((parentId: targetItem.targetId, targetId: childId))
    }

    // Resolve the target
    targetResolver.resolve(
      targetId: targetItem.targetId,
      ResolvedTarget(
        parent: targetItem.parentId,
        simpleName: partialResolvedTarget.simpleName,
        navigationName: partialResolvedTarget.navigationName,
        children: partialResolvedTarget.children.filter { otherFile($0) == nil },  // other files should not show up anywhere
        relativePath: relativePath
      )
    )
  }

  return targetResolver
}

/// Try and get the id if the target is of type "other file" else return nil
private func otherFile(_ targetId: AnyTargetID) -> OtherLocalFileAsset.ID? {
  if case .asset(let assetId) = targetId {
    if case .otherFile(let otherFileId) = assetId {
      return otherFileId
    }
  }

  return nil
}

/// Get relative path to the target
private func relativePathToParent(
  _ targetResolver: TargetResolver, of parentId: AnyTargetID?, with pathName: String
) -> RelativePath {
  if let parentPath = targetResolver[parentId]?.relativePath {
    var relativePath = parentPath / ".." / pathName
    relativePath.resolve()
    return relativePath
  }

  return RelativePath(pathString: pathName)
}
