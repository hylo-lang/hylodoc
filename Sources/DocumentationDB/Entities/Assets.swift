import DequeModule
import Foundation
import FrontEnd
import MarkdownKit

/// A protocol for assets in the documentation database.
public protocol Asset {
  /// The location of the asset on the filesystem.
  var location: URL { get }

  /// Either the file or folder name of the asset.
  var name: String { get }
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

  public init(location: URL, documentation: ArticleAsset.ID?, children: [AnyAssetID]) {
    self.location = location
    self.documentation = documentation
    self.children = children
  }
}

/// An asset representing an article in the project, which is stored inside a .hylodoc file.
public struct ArticleAsset: IdentifiedEntity, Asset {
  public let location: URL

  /// The title of the article, if present at the beginning of the document
  public let title: String?

  /// The content of the article, excluding the first-level heading at the beginning, if present.
  public let content: Block

  public init(location: URL, title: String?, content: Block) {
    self.location = location
    self.title = title
    self.content = content
  }
}

// Sourcefile-level documentation
public struct SourceFileAsset: IdentifiedEntity, Asset {
  public let location: URL

  /// The optional file-level documentation for the source file.
  public let generalDescription: GeneralDescriptionFields

  /// The translation unit ID that this source file belongs to.
  public let translationUnit: TranslationUnit.ID
}

/// An asset representing any other kind of file in the project - e.g. images, attachments, etc.
///
/// This is useful for linking to files in the project that are not source files.
public struct OtherLocalFileAsset: IdentifiedEntity, Asset {
  public let location: URL

  init(location: URL) {
    self.location = location
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
}
