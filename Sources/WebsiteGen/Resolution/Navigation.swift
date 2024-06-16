import PathWrangler

public struct NavigationItem {
  // General Information
  let id: AnyTargetID
  let name: String
  let relativePath: RelativePath
  let cssClassOfTarget: String

  // Relations
  let children: [NavigationItem]
}

public struct BreadcrumbItem {
  let name: String
  let relativePath: RelativePath

  public init(name: String, relativePath: RelativePath) {
    self.name = name
    self.relativePath = relativePath
  }
}

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
