import DequeModule
import Foundation
import FrontEnd
import MarkdownKit

/// A protocol for assets in the documentation database.
public protocol Asset: IdentifiedEntity {
  /// The location of the asset on the filesystem.
  var location: URL { get }

  /// Either the file or folder name of the asset.
  var name: String { get }

  associatedtype EntityStoreT: ReadableEntityStoreProtocol where EntityStoreT.Entity == Self
  static func specificStore(from: AssetStore) -> EntityStoreT
}

/// Default implementation to get name from the location's last path component.
extension Asset {
  public var name: String {
    return location.lastPathComponent
  }
}

/// An asset representing a folder in the project, containing other assets.
public struct FolderAsset: IdentifiedEntity, Asset {
  public let location: URL

  /// The documentation article for the module, if exists (a index.hylodoc file located in this folder)
  public let documentation: ArticleAsset.ID?

  /// The list of child assets in this folder
  public let children: [AnyAssetID]

  /// Id of a module in which the folder is contained in.
  ///
  /// Used for name resolution for embedded hylo references.
  public let moduleId: ModuleDecl.ID

  public init(
    location: URL, documentation: ArticleAsset.ID?, children: [AnyAssetID], moduleId: ModuleDecl.ID
  ) {
    self.location = location
    self.documentation = documentation
    self.children = children
    self.moduleId = moduleId
  }

  public typealias EntityStoreT = EntityStore<FolderAsset>
  public static func specificStore(from assets: AssetStore) -> EntityStoreT {
    return assets.folders
  }
}

/// An asset representing an article in the project, which is stored inside a .hylodoc file.
public struct ArticleAsset: IdentifiedEntity, Asset, Equatable {
  public let location: URL

  /// The title of the article, if present at the beginning of the document
  public let title: String?

  /// The content of the article, excluding the first-level heading at the beginning, if present.
  public let content: Block

  /// The ID of the module in which the article is located.
  ///
  /// Used for name resolution for embedded hylo references.
  public let moduleId: ModuleDecl.ID

  /// Check if the article is internal
  public var isInternal: Bool {
    return location.lastPathComponent.hasSuffix(".internal.hylodoc")
  }

  public init(location: URL, title: String?, content: Block, moduleId: ModuleDecl.ID) {
    self.location = location
    self.title = title
    self.content = content
    self.moduleId = moduleId
  }

  public typealias EntityStoreT = EntityStore<ArticleAsset>
  public static func specificStore(from assets: AssetStore) -> EntityStoreT {
    return assets.articles
  }
}

// Sourcefile-level documentation
public struct SourceFileAsset: IdentifiedEntity, Asset, Equatable {
  public let location: URL

  /// The optional file-level documentation for the source file.
  public let generalDescription: GeneralDescriptionFields

  /// The translation unit ID that this source file belongs to.
  public let translationUnit: TranslationUnit.ID

  public init(
    location: URL, generalDescription: GeneralDescriptionFields, translationUnit: TranslationUnit.ID
  ) {
    self.location = location
    self.generalDescription = generalDescription
    self.translationUnit = translationUnit
  }

  public typealias EntityStoreT = AdaptedEntityStore<TranslationUnit, SourceFileAsset>
  public static func specificStore(from assets: AssetStore) -> EntityStoreT {
    return assets.sourceFiles
  }
}

/// An asset representing any other kind of file in the project - e.g. images, attachments, etc.
///
/// This is useful for linking to files in the project that are not source files.
public struct OtherLocalFileAsset: IdentifiedEntity, Asset, Equatable {
  public let location: URL

  public init(location: URL) {
    self.location = location
  }

  public typealias EntityStoreT = EntityStore<OtherLocalFileAsset>
  public static func specificStore(from assets: AssetStore) -> EntityStoreT {
    return assets.otherFiles
  }
}

/// An identifier that uniquely identifies an asset in the documentation database.
///
/// It stores the type of the asset and the local ID of the asset within that type.
/// (It is a composite key.)
public enum AnyAssetID: Equatable, Hashable {
  case sourceFile(SourceFileAsset.ID)
  case article(ArticleAsset.ID)
  case folder(FolderAsset.ID)
  case otherFile(OtherLocalFileAsset.ID)

  public init(_ from: SourceFileAsset.ID) {
    self = .sourceFile(from)
  }
  public init(_ from: ArticleAsset.ID) {
    self = .article(from)
  }
  public init(_ from: FolderAsset.ID) {
    self = .folder(from)
  }
  public init(_ from: OtherLocalFileAsset.ID) {
    self = .otherFile(from)
  }
}

public struct AssetStore {
  public var folders: EntityStore<FolderAsset> = .init()
  public var sourceFiles: AdaptedEntityStore<TranslationUnit, SourceFileAsset> = .init()
  public var articles: EntityStore<ArticleAsset> = .init()
  public var otherFiles: EntityStore<OtherLocalFileAsset> = .init()

  public func url(of: AnyAssetID) -> URL? {
    switch of {
    case .sourceFile(let id):
      return sourceFiles[id]?.location
    case .article(let id):
      return articles[id]?.location
    case .folder(let id):
      return folders[id]?.location
    case .otherFile(let id):
      return otherFiles[id]?.location
    }
  }

  public subscript(_ id: AnyAssetID) -> (any Asset)? {
    switch id {
    case .sourceFile(let id):
      return sourceFiles[id]
    case .article(let id):
      return articles[id]
    case .folder(let id):
      return folders[id]
    case .otherFile(let id):
      return otherFiles[id]
    }
  }

  public subscript<T: Asset>(_ id: T.ID) -> T? {
    let a = T.specificStore(from: self)
    return a[id]
  }

  public init() {}
}

extension AssetStore {
  // Finds an asset by its URL.
  // 
  // Complexity: O(n) where n is the number of assets in the store.
  public func find(url: URL) -> AnyAssetID? {
    let url = url.standardized

    if let matchingArticleId = articles.firstIndex(where: { $0.location.standardized == url }) {
      return .article(matchingArticleId)
    }
    if let matchingSourceFileId = sourceFiles.firstIndex(where: { $0.location.standardized == url }) {
      return .sourceFile(matchingSourceFileId)
    }
    if let matchingFolderId = folders.firstIndex(where: { $0.location.standardized == url }) {
      return .folder(matchingFolderId)
    }
    if let matchingOtherFileId = otherFiles.firstIndex(where: { $0.location.standardized == url }) {
      return .otherFile(matchingOtherFileId)
    }
    return nil
  }
}
