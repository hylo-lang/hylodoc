import DequeModule
import DocumentationDB
import Foundation
import FrontEnd

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
    let url = urlRelativeToParent(
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
        id: targetItem.targetId,
        parent: targetItem.parentId,
        simpleName: partialResolved.simpleName,
        navigationName: partialResolved.navigationName,
        children: partialResolved.children.filter { !isDirectlyCopiedAssetTarget($0) },  // other files should not show up anywhere
        url: url
      )
    )

    // Resolve any references back to this target that are not supposed to have their own page
    if let backReferences = backReferencesOfTarget(typedProgram, targetId: targetItem.targetId) {
      backReferences.forEach {
        targetResolver.resolveBackReference(from: $0, backTo: targetItem.targetId)
      }
    }
  }

  return targetResolver
}

/// Get relative path to the target
func urlRelativeToParent(
  _ targetResolver: TargetResolver, of parentId: AnyTargetID?, with pathComponent: String
) -> URL {
  if let url = targetResolver[parentId]?.url {
    return url.deletingLastPathComponent().appendingPathComponent(pathComponent)
  }

  return URL(fileURLWithPath: "/" + pathComponent)
}
