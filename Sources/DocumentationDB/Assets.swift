public struct AssetCommon {
  /// The URL of the asset within the project.
  public let url: ProjectURL

  /// The parent module of this asset, if it exists - nil if this is the root module.
  public let parentModule: AssetID?
}

public struct SourceFileAsset {
  public typealias ID = CustomID<SourceFileAsset>

  /// Common asset information.
  public let common: AssetCommon

  /// File name without .hylo extension.
  public let name: String

  /// Present if there is a file-level docstring comment.
  public let summary: String?

  /// Present if there is a file-level docstring comment with more than just a summary.
  public let description: String?

  /// The list of top-level declared symbols in the source file, ordered by appearance in the file.
  public let symbols: [SymbolID]
}

/// An asset representing an article in the project, which is stored inside a .hylodoc file.
public struct ArticleAsset {
  public typealias ID = CustomID<ArticleAsset>

  /// Common asset information.
  public let common: AssetCommon

  /// The title of the article, if present at the beginning of the document.
  public let title: String?

  /// The content of the article, excluding the first-level heading at the beginning, if present.
  public let content: MarkdownNode
}

/// An asset representing a module in the project, which is essentially a folder containing other assets.
public struct ModuleAsset {
  public typealias ID = CustomID<ModuleAsset>

  /// Common asset information.
  public let common: AssetCommon

  /// The name of the module.
  public let name: String

  /// The documentation article for the module, if exists.
  public let documentation: ArticleAsset.ID?

  /// The list of child assets in this module.
  public let children: [AssetID]
}

/// An asset representing any other kind of file in the project - e.g. images, attachments, etc.
///
/// This is useful for linking to files in the project that are not source files.
public struct OtherLocalFileAsset {
  public typealias ID = CustomID<OtherLocalFileAsset>

  /// Common asset information
  public let common: AssetCommon
}

/// An identifier that uniquely identifies an asset in the documentation database.
///
/// It stores the type of the asset and the local ID of the asset within that type.
/// (It is a composite key.)
public enum AssetID {
  case sourceFile(SourceFileAsset.ID)
  case article(ArticleAsset.ID)
  case module(ModuleAsset.ID)
  case otherFile(OtherLocalFileAsset.ID)
}

public struct AssetDatabase {
  public var modules: EntityStore<ModuleAsset> = .init()
  public var sourceFiles: EntityStore<SourceFileAsset> = .init()
  public var articles: EntityStore<ArticleAsset> = .init()
  public var otherFiles: EntityStore<OtherLocalFileAsset> = .init()
}
