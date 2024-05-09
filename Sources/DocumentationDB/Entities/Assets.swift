import FrontEnd

/// An asset representing a module in the project, which is essentially a folder containing other assets.
public struct ModuleAsset : IdentifiedEntity {
  /// The name of the module (the folder name)
  public let name: String

  /// The documentation article for the module, if exists
  public let documentation: ArticleAsset.ID?

  /// The list of child assets in this module
  public let children: [AnyAssetID]
}

/// An asset representing an article in the project, which is stored inside a .hylodoc file.
public struct ArticleAsset : IdentifiedEntity {
  public let fileName: String

  /// The title of the article, if present at the beginning of the document
  public let title: String?

  /// The content of the article, excluding the first-level heading at the beginning, if present.
  public let content: AnyMarkdownNodeID
}


// Sourcefile-level documentation
public struct SourceFileAsset: IdentifiedEntity {
  public let generalDescription: GeneralDescriptionFields
}

/// An asset representing any other kind of file in the project - e.g. images, attachments, etc.
///
/// This is useful for linking to files in the project that are not source files.
public struct OtherLocalFileAsset : IdentifiedEntity {
  public let fileName: String
}


/// An identifier that uniquely identifies an asset in the documentation database.
///
/// It stores the type of the asset and the local ID of the asset within that type.
/// (It is a composite key.)
public enum AnyAssetID : Equatable, Hashable {
  case sourceFile(SourceFileAsset.ID)
  case article(ArticleAsset.ID)
  case module(ModuleAsset.ID)
  case otherFile(OtherLocalFileAsset.ID)
}

public struct AssetStore {
  public var modules: AdaptedEntityStore<ModuleDecl> = .init()
  public var sourceFiles: AdaptedEntityStore<TranslationUnit> = .init()
  public var articles: EntityStore<ArticleAsset> = .init()
  public var otherFiles: EntityStore<OtherLocalFileAsset> = .init()
}