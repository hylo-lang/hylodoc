import DocumentationDB
import Foundation
import FrontEnd
import HDCUtils
import MarkdownKit

public struct InputModuleInfo {
  public let name: String
  public let rootFolderPath: URL
  public let astId: ModuleDecl.ID
  public let openSourceUrlBase: URL?

  public init(name: String, rootFolderPath: URL, astId: ModuleDecl.ID, openSourceUrlBase: URL?) {
    self.name = name
    self.rootFolderPath = rootFolderPath
    self.astId = astId
    self.openSourceUrlBase = openSourceUrlBase
  }
}

extension ModuleInfo {
  init(inputInfo: InputModuleInfo, rootFolderId: FolderAsset.ID) {
    self.init(
      name: inputInfo.name,
      rootFolderPath: inputInfo.rootFolderPath,
      astId: inputInfo.astId,
      rootFolder: rootFolderId,
      openSourceUrlBase: inputInfo.openSourceUrlBase
    )
  }
}

func splitArticleIntoTitleAndRest(content: Block) -> (title: String?, rest: Block) {
  guard case let .document(blocks) = content, case let .heading(1, text) = blocks.first else {
    return (nil, content)
  }
  return (text.rawDescription, .document(.init(blocks.dropFirst())))
}

func collectTranslationUnitsByURL(ast: AST) -> [URL: TranslationUnit.ID] {
  struct ASTWalker: ASTWalkObserver {
    var translationUnitsByURL: [URL: TranslationUnit.ID] = [:]
    mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
      if let tuID = TranslationUnit.ID(id) {
        translationUnitsByURL[ast[tuID].site.file.url] = tuID
        return false
      }
      return true
    }
  }

  var luke = ASTWalker()
  for m in ast.modules {
    ast.walk(m, notifying: &luke)
  }

  return luke.translationUnitsByURL
}

public struct DocDBBuildingAssetScanner<SFDocumentor: SourceFileDocumentor>: AssetProcessingVisitor
{
  public enum ArticleProcessingError: Error {
    case fileReadingError(URL, Error)
  }
  public enum SourceFileProcessingError: Error, CustomStringConvertible {
    case noTranslationUnitFound(for: URL)
    case processingIssue(HDCDiagnosticSet)

    public var description: String {
      switch self {
      case .noTranslationUnitFound(for: let url):
        return "No translation unit found for source file at \(url)"
      case .processingIssue(let diagnostics):  // todo expose diagnostics rendering from the Hylo driver
        return diagnostics.elements.map { " - \($0.description)\n\n" }.joined()
      }
    }
  }
  public enum OtherLocalFileProcessingError: Error {}
  public enum FolderProcessingError: Error {}

  // Inputs:
  private let modules: [InputModuleInfo]
  private var typedProgram: TypedProgram
  private let standardizedModulePathsToModuleIds: [(url: URL, moduleId: ModuleDecl.ID)]

  // Products:
  private var assets: AssetStore = .init()
  private var symbolDocs: SymbolDocStore = .init()
  private let translationUnitsByURL: [URL: TranslationUnit.ID]

  // Dependencies:
  private var fileManager: FileManager
  private let markdownParser: MarkdownParser
  private let sourceFileDocumentor: SFDocumentor

  public init(
    modules: [InputModuleInfo],
    typedProgram: TypedProgram,
    sourceFileDocumentor: SFDocumentor,
    fileManager: FileManager = .default,
    markdownParser: MarkdownParser = HyloDocMarkdownParser.standard
  ) {
    self.modules = modules
    self.typedProgram = typedProgram
    self.fileManager = fileManager
    self.markdownParser = markdownParser
    self.translationUnitsByURL = collectTranslationUnitsByURL(ast: typedProgram.ast)
    self.sourceFileDocumentor = sourceFileDocumentor
    self.standardizedModulePathsToModuleIds = modules.map {
      ($0.rootFolderPath.standardized, $0.astId)
    }
  }

  public mutating func processArticle(path: URL) -> Result<ArticleAsset.ID, ArticleProcessingError>
  {
    Result { try String.init(contentsOf: path, encoding: .utf8) }
      .mapError { .fileReadingError(path, $0) }
      .map { fileContents in
        let content = markdownParser.parse(fileContents)

        let (title, rest) = splitArticleIntoTitleAndRest(content: content)
        return assets.articles.insert(
          .init(
            location: path,
            title: title,
            content: rest,
            moduleId: moduleOf(assetUrl: path)!
          )
        )
      }
  }

  public mutating func processSourceFile(path: URL) ->  //
    Result<SourceFileAsset.ID, SourceFileProcessingError>
  {
    guard let tuID = translationUnitsByURL[path] else {
      return .failure(.noTranslationUnitFound(for: path))
    }

    var diagnostics = HDCDiagnosticSet()
    let fileLevelGeneralDescription = sourceFileDocumentor.document(
      ast: typedProgram.ast, translationUnitId: tuID, into: &symbolDocs, diagnostics: &diagnostics)

    guard diagnostics.isEmpty else {
      return .failure(.processingIssue(diagnostics))
    }

    return .success(
      assets.sourceFiles.insert(
        .init(
          location: path,
          generalDescription: fileLevelGeneralDescription,
          translationUnit: tuID
        ),
        for: tuID
      )
    )
  }

  public mutating func processOtherAsset(path: URL) ->  //
    Result<OtherLocalFileAsset.ID, OtherLocalFileProcessingError>
  {
    .success(assets.otherFiles.insert(.init(location: path)))
  }

  public mutating func processFolder(
    path: URL, children: some Sequence<AnyAssetID>, documentation: ArticleAsset.ID?
  ) -> Result<FolderAsset.ID, FolderProcessingError> {
    .success(
      assets.folders.insert(
        .init(
          location: path,
          documentation: documentation,
          children: Array(children),
          moduleId: moduleOf(assetUrl: path)!
        )
      )
    )
  }

  public mutating func build() -> Result<DocumentationDatabase, DocExtractionError<Self>> {
    modules
      .map { (module: InputModuleInfo) in
        recursivelyVisitFolder(
          folderPath: module.rootFolderPath.absoluteURL,
          visitor: &self,
          fileManager: fileManager
        )
        .map { (module, rootFolderId: $0) }
      }
      .collectResults()
      .map { (extendedModuleInfos: [(module: InputModuleInfo, rootFolderId: FolderAsset.ID)]) in
        DocumentationDatabase(
          assets: assets,
          symbols: symbolDocs,
          modules: .init(from: extendedModuleInfos.map(ModuleInfo.init).map { ($0, $0.astId) })
        )
      }
  }

  func moduleOf(assetUrl: URL) -> ModuleDecl.ID? {
    let assetPathComponents = assetUrl.standardized.pathComponents

    return standardizedModulePathsToModuleIds.first { (moduleUrl, _) in
      return assetPathComponents.starts(with: moduleUrl.pathComponents)
    }?.moduleId
  }
}

// todo make the error type independent of the dependency on the documentor
/// Scans the assets in the given modules and calls the visitor for each asset.
public func extractDocumentation(typedProgram: TypedProgram, for modules: [InputModuleInfo]) ->  //
  Result<
    DocumentationDatabase, DocExtractionError<DocDBBuildingAssetScanner<RealSourceFileDocumentor>>
  >
{
  let commentParser = RealCommentParser(lowLevelCommentParser: RealLowLevelCommentParser())
  let sourceFileDocumentor = RealSourceFileDocumentor(
    commentParser: commentParser, markdownParser: HyloDocMarkdownParser.standard)
  var builder = DocDBBuildingAssetScanner(
    modules: modules,
    typedProgram: typedProgram,
    sourceFileDocumentor: sourceFileDocumentor
  )
  return builder.build()
}
