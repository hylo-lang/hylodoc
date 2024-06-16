import PathWrangler

public struct NavigationItem {
  // General Information
  let name: String
  let relativePath: RelativePath
  let cssClassOfTarget: String

  // Relations
  let children: [AnyTargetID]
}

public typealias BreadcrumbItem = (name: String, relativePath: RelativePath)

// Get the class used for the navigation item
func getCssClassOfTarget(_ targetId: AnyTargetID) -> String {
  return switch targetId {
  case .asset(let assetId):
    switch assetId {
    case .folder(_):
      "folder"  // folder icon
    case .article(_):
      "article"  // article icon
    case .sourceFile(_):
      "source-file"  // source-file icon
    default:
      ""  // has no icon
    }
  default:
    "symbol"  // has no icon, used to distinct between symbols and assets
  }
}
