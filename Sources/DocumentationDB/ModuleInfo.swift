import Foundation

public struct ModuleInfo : IdentifiedEntity {
    public let name: String
    public let path: URL
    public let rootFolder: FolderAsset.ID
}