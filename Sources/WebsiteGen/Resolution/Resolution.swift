import DequeModule
import DocumentationDB
import FrontEnd
import PathWrangler

typealias TargetItem = (parentId: AnyTargetID?, targetId: AnyTargetID)

public func resolveTargets(documentationDatabase: DocumentationDatabase, typedProgram: TypedProgram)
  -> TargetResolver
{
  // Initialize queue with the root items
  var queue: Deque<TargetItem> = Deque(
    documentationDatabase.modules.map {
      TargetItem(
        parentId: nil,
        targetId: .asset(.folder($0.rootFolder))
      )
    })

  // Traverse until every target has been visited
  var targetResolver = TargetResolver()
  while !queue.isEmpty {
    let targetItem = queue.popLast()!

    // Resolve only the path to an asset of type "other file" as they don't show up anywhere else
    if isDirectlyCopiedAssetTarget(targetItem.targetId) {
      let otherResolved = resolveDirectlyCopiedAssetTarget(
        documentationDatabase,
        targetResolver,
        targetId: targetItem.targetId,
        parentId: targetItem.parentId)

      targetResolver.resolveOther(targetId: targetItem.targetId, otherResolved)
      continue
    }

    // Partially resolve target
    let partialResolved = partialResolveTarget(
      documentationDatabase,
      typedProgram,
      targetId: targetItem.targetId
    )

    // Get relative path to the target
    let relativePath = relativePathToParent(
      targetResolver,
      of: targetItem.parentId,
      with: partialResolved.pathName
    )

    // Add the children of the target to the queue
    for childId in partialResolved.children {
      queue.append((parentId: targetItem.targetId, targetId: childId))
    }

    // Resolve the target
    targetResolver.resolve(
      targetId: targetItem.targetId,
      ResolvedTarget(
        parent: targetItem.parentId,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children.filter { !isDirectlyCopiedAssetTarget($0) },  // other files should not show up anywhere
        relativePath: relativePath
      )
    )
  }

  return targetResolver
}

/// Get relative path to the target
func relativePathToParent(
  _ targetResolver: TargetResolver, of parentId: AnyTargetID?, with pathName: String
) -> RelativePath {
  if let parentPath = targetResolver[parentId]?.relativePath {
    var relativePath = parentPath / ".." / pathName
    relativePath.resolve()
    return relativePath
  }

  return RelativePath(pathString: pathName)
}
