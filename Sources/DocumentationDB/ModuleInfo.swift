import Foundation
import FrontEnd

public struct ModuleInfo: IdentifiedEntity {
  public let name: String
  public let rootFolderPath: URL
  public let rootFolder: FolderAsset.ID
  public let astId: ModuleDecl.ID

  public init(name: String, rootFolderPath: URL, astId: ModuleDecl.ID, rootFolder: FolderAsset.ID) {
    self.name = name
    self.rootFolderPath = rootFolderPath
    self.rootFolder = rootFolder
    self.astId = astId
  }
}
