import DocumentationDB
import Foundation
import FrontEnd

/// A structure representing a source file with associated comments.
struct CommentedFile {

  private let source: SourceFile
  private let commentParser: LowLevelCommentParser

  private(set) var symbolComments: [TargetedSymbolDocInfo]
  private(set) var fileComment: FileLevelInfo?

  /// Initializes a `CommentedFile` with a given source file and comment parser.
  ///
  /// - Parameters:
  ///   - sourceFile: The source file to extract comments from.
  ///   - commentParser: The parser used to parse the comments.
  init(_ sourceFile: SourceFile, _ commentParser: LowLevelCommentParser) {
    self.source = sourceFile
    self.commentParser = commentParser
    symbolComments = [TargetedSymbolDocInfo]()
    extractComments()
  }

  /// Retrieves the comment for a symbol at a specific start index.
  ///
  /// - Parameter index: The starting index of a symbol in the source file to retrieve the comment for.
  /// - Returns: The comment source at the given index, or nil if no comment is found.
  public func getSymbolComment(_ startIndex: SourceFile.Index) -> SymbolDocInfo? {
    return symbolComments.first { $0.target == startIndex }?.info
  }

  /// Extracts all symbol & file-level comments from the source file using the comment parser.
  private mutating func extractComments() {
    let tokens = Array(Lexer(tokenizing: source))
    var curIndex: SourceFile.Index = source.text.startIndex

    for token in tokens {
      let tokenSite = token.site
      processTokenRange(curIndex, tokenSite.startIndex)
      curIndex = tokenSite.endIndex
    }

    processTokenRange(curIndex, source.text.endIndex)
  }

  /// Processes a range of the source file to extract comments.
  ///
  /// - Parameters:
  ///   - start: The starting index of the range.
  ///   - end: The ending index of the range.
  ///
  /// - Precondition: The range should not contain any tokens.
  private mutating func processTokenRange(_ start: SourceFile.Index, _ end: SourceFile.Index) {
    let content = source.text[start ..< end]
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
    processLines(lines, end)
  }

  /// Processes lines of text to identify and extract comments.
  ///
  /// - Parameters:
  ///   - lines: The lines of text to process.
  ///   - target: The target index for the comment.
  private mutating func processLines(_ lines: [Substring], _ target: SourceFile.Index) {
    var commentLines = [String]()

    var startedComment = false
    var finishedComment = false

    for i in 0 ..< lines.count {
      let trimmed = lines[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      let isCommentLine = trimmed.hasPrefix("///")

      if isCommentLine {
        if finishedComment {
          addComment(commentLines, nil)
          commentLines.removeAll()
          startedComment = false
          finishedComment = false
        }

        if !startedComment {
          startedComment = true
        }

        commentLines.append(trimmed)
      } else {
        if startedComment && !finishedComment {
          finishedComment = true
        }
      }
    }

    if startedComment {
      addComment(commentLines, target)
    }
  }

  /// Adds a comment to the appropriate list based on its type.
  ///
  /// - Parameters:
  ///   - lines: The lines of the comment.
  ///   - target: The target index for the symbol comment, if applicable.
  private mutating func addComment(_ lines: [String], _ target: SourceFile.Index?) {
    let info = commentParser.parse(lines)

    switch info {
    case .FileLevel(let fileInfo):
      if self.fileComment != nil {
        print("ERROR: Multiple file-level comments")
        return
      }

      self.fileComment = fileInfo
    case .SymbolDoc(let symbolInfo):
      if target == nil {
        print("ERROR: No target for symbol comment")
        return
      }

      let targetedSymbolInfo = TargetedSymbolDocInfo(symbolInfo, target!)
      symbolComments.append(targetedSymbolInfo)
    }
  }
}

// A structure representing a symbol documentation with its associated target symbol index
struct TargetedSymbolDocInfo {
  public let info: SymbolDocInfo
  public let target: SourceFile.Index

  init(_ info: SymbolDocInfo, _ target: SourceFile.Index) {
    self.info = info
    self.target = target
  }
}

public struct FileLevelInfo {
  public let text: String

  init(_ text: String) {
    self.text = text
  }
}

public struct SymbolDocInfo {
  public let text: String

  init(_ text: String) {
    self.text = text
  }
}

public enum LowLevelInfo {
  case FileLevel(info: FileLevelInfo)
  case SymbolDoc(info: SymbolDocInfo)
}

public protocol LowLevelCommentParser {
  func parse(_ commentLines: [String]) -> LowLevelInfo
}
