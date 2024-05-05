import Foundation

/// A project URL is a URL that points to a file or folder within the project.
///
/// We use a custom scheme `project://` to distinguish these URLs from regular URLs.
public struct ProjectURL {
    public let url: URL

    public init(_ url: URL) {
        assert(url.isFileURL && url.scheme == "project", "URL must be a file url with the scheme project://") 
        self.url = url
    }
}


public struct DocumentationDatabase {
    var rootModuleId: ModuleAsset.ID
    var assets: AssetDatabase = .init()
    var symbols: SymbolDatabase = .init()
}