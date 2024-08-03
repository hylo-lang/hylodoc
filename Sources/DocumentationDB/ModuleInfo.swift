import Foundation
import FrontEnd

public struct ModuleInfo: IdentifiedEntity {
  public let name: String
  public let rootFolderPath: URL
  public let rootFolder: FolderAsset.ID
  public let astId: ModuleDecl.ID
  /// The base URL for the open source repository where we should link to the source code.
  /// 
  /// E.g. https://github.com/hylo-lang/hylo/blob/main/StandardLibrary/Sources/
  public let openSourceUrlBase: URL?

  public init(name: String, rootFolderPath: URL, astId: ModuleDecl.ID, rootFolder: FolderAsset.ID, openSourceUrlBase: URL?) {
    self.name = name
    self.rootFolderPath = rootFolderPath
    self.rootFolder = rootFolder
    self.astId = astId
    self.openSourceUrlBase = openSourceUrlBase
  }
}
