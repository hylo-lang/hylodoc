import DocumentationDB
import Foundation
import FrontEnd

public protocol AssetProcessingVisitor {
  associatedtype ArticleProcessingError: Error
  associatedtype SourceFileProcessingError: Error
  associatedtype OtherLocalFileProcessingError: Error
  associatedtype FolderProcessingError: Error

  mutating func processArticle(path: URL) -> Result<ArticleAsset.ID, ArticleProcessingError>

  mutating func processSourceFile(path: URL) ->  //
    Result<SourceFileAsset.ID, SourceFileProcessingError>

  mutating func processOtherAsset(path: URL) ->  //
    Result<OtherLocalFileAsset.ID, OtherLocalFileProcessingError>

  mutating func processFolder(
    path: URL,
    children: some Sequence<AnyAssetID>,
    documentation: ArticleAsset.ID?
  ) -> Result<FolderAsset.ID, FolderProcessingError>
}

public enum DocExtractionError<Visitor: AssetProcessingVisitor>: Error, CustomStringConvertible {
  case scanningSubfoldersError(URL, Error)
  case sourceFileProcessingError(URL, Visitor.SourceFileProcessingError)
  case articleProcessingError(URL, Visitor.ArticleProcessingError)
  case otherLocalFileProcessingError(URL, Visitor.OtherLocalFileProcessingError)
  case folderProcessingError(URL, Visitor.FolderProcessingError)

  public var description: String {
    switch self {
    case let .scanningSubfoldersError(url, error):
      return "Error scanning subfolders of \(url):\n\(error)"
    case let .sourceFileProcessingError(_, error):
      return "Error processing source file:\n\(error)"
    case let .articleProcessingError(url, error):
      return "Error processing article at \(url):\n\(error)"
    case let .otherLocalFileProcessingError(url, error):
      return "Error processing other local file at \(url):\n\(error)"
    case let .folderProcessingError(url, error):
      return "Error processing folder at \(url):\n\(error)"
    }
  }
}

extension Array {
  /// Collects the results of an array of results into a single result.
  func collectResults<T, E>() -> Result<[T], E> where Element == Result<T, E> {
    var collectedValues = [T]()
    collectedValues.reserveCapacity(self.count)

    for result in self {
      switch result {
      case .success(let value):
        collectedValues.append(value)
      case .failure(let error):
        return .failure(error)
      }
    }

    return .success(collectedValues)
  }
}

extension FileManager {
  func listFolderEntries(path: URL) -> Result<[URL], Error> {
    return .init {
      try self.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
    }
  }
}

func processChild<Visitor: AssetProcessingVisitor>(
  path: URL, visitor: inout Visitor, fileManager: FileManager
) -> Result<(AnyAssetID, folderDoc: ArticleAsset.ID?), DocExtractionError<Visitor>> {
  if path.hasDirectoryPath {
    return recursivelyVisitFolder(folderPath: path, visitor: &visitor, fileManager: fileManager)
      .map { (AnyAssetID(from: $0), folderDoc: nil) }
  }

  switch path.pathExtension {
  case "hylo":
    return visitor.processSourceFile(path: path)
      .map { (AnyAssetID(from: $0), folderDoc: nil) }
      .mapError { .sourceFileProcessingError(path, $0) }
  case "hylodoc":
    return visitor.processArticle(path: path)
      .map {
        (
          AnyAssetID(from: $0),
          folderDoc: path.lastPathComponent == "index.hylodoc" ? $0 : nil
        )
      }
      .mapError { .articleProcessingError(path, $0) }
  default:
    return visitor.processOtherAsset(path: path)
      .map { (AnyAssetID(from: $0), folderDoc: nil) }
      .mapError { .otherLocalFileProcessingError(path, $0) }
  }
}

/// Returns the id of the created folder asset
func recursivelyVisitFolder<Visitor: AssetProcessingVisitor>(
  folderPath: URL, visitor: inout Visitor, fileManager: FileManager
) -> Result<FolderAsset.ID, DocExtractionError<Visitor>> {

  var documentationArticle: ArticleAsset.ID? = nil

  return fileManager.listFolderEntries(path: folderPath)
    .mapError { DocExtractionError.scanningSubfoldersError(folderPath, $0) }
    .flatMap { childEntries in
      childEntries.map { childEntry -> Result<AnyAssetID, DocExtractionError> in
        processChild(path: childEntry, visitor: &visitor, fileManager: fileManager)
          .map { (childId, folderDoc) in
            if let folderDoc = folderDoc {
              documentationArticle = folderDoc
            }
            return childId
          }
      }
      .collectResults()
    }
    .flatMap { childAssetIds in
      visitor
        .processFolder(
          path: folderPath, children: childAssetIds, documentation: documentationArticle
        )
        .mapError { DocExtractionError<Visitor>.folderProcessingError(folderPath, $0) }
    }
}
