import DocumentationDB
import Foundation
import FrontEnd

public struct DocumentedFile {
  /// The file-level comment if it exists.
  public let fileLevel: SourceRepresentable<LowLevelCommentInfo>?

  /// The comment at the given start index of a symbol
  public let symbolComments: [SourceFile.Index: SourceRepresentable<LowLevelCommentInfo>]
}

public protocol CommentParser {
  /// Returns the comments extracted from the source file if there are no errors and reports any issues in the diagnostics parameter
  func parse(sourceFile: SourceFile, diagnostics: inout DiagnosticSet) -> DocumentedFile?
}

/// A structure representing a source file with associated comments.
public struct RealCommentParser<LLCommentParser: LowLevelCommentParser>: CommentParser {
  private let lowLevelCommentParser: LLCommentParser

  public init(lowLevelCommentParser: LLCommentParser) {
    self.lowLevelCommentParser = lowLevelCommentParser
  }

  public func parse(sourceFile: SourceFile, diagnostics: inout DiagnosticSet) -> DocumentedFile? {
    let builder = DocumentedFileBuilder(sourceFile, lowLevelCommentParser)
    diagnostics.formUnion(builder.diagnostics)

    guard !builder.diagnostics.containsError else {
      return nil
    }
    return DocumentedFile(
      fileLevel: builder.fileComment,
      symbolComments: builder.symbolComments
    )
  }
}

private struct DocumentedFileBuilder<LLCommentParser: LowLevelCommentParser> {
  private let source: SourceFile
  private let commentParser: LLCommentParser

  /// A list of symbol comments associated with their target index.
  public private(set) var symbolComments:
    [SourceFile.Index: SourceRepresentable<LowLevelCommentInfo>] = [:]
  public private(set) var fileComment: SourceRepresentable<LowLevelCommentInfo>?
  public private(set) var diagnostics: DiagnosticSet = .init()

  /// Initializes a `CommentedFile` with a given source file and comment parser.
  ///
  /// - Parameters:
  ///   - sourceFile: The source file to extract comments from.
  ///   - commentParser: The parser used to parse the comments.
  public init(_ sourceFile: SourceFile, _ commentParser: LLCommentParser) {
    self.source = sourceFile
    self.commentParser = commentParser
    extractComments()
  }

  /// Extracts all symbol & file-level comments from the source file using the comment parser.
  private mutating func extractComments() {
    let tokens = Array(Lexer(tokenizing: source))
    var curIndex: SourceFile.Index = source.text.startIndex

    for token in tokens {
      processTokenRange(from: curIndex, until: token.site.startIndex)
      curIndex = token.site.endIndex
    }

    processTokenRange(from: curIndex, until: nil)
  }

  /// Processes a range of the source file to extract comments.
  ///
  /// - Parameters:
  ///   - start: The starting index of the range.
  ///   - end: The ending index of the range.
  ///
  /// - Precondition: The range should not contain any tokens.
  private mutating func processTokenRange(
    from start: SourceFile.Index, until end: SourceFile.Index?
  ) {
    let content = source.text[start..<(end != nil ? end! : source.text.endIndex)]
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
    processLines(lines, end)
  }

  /// Processes lines of text to identify and extract comments.
  ///
  /// - Parameters:
  ///   - lines: The lines of text to process.
  ///   - target: The target index for the comment.
  private mutating func processLines(_ lines: [Substring], _ target: SourceFile.Index?) {
    var commentLines: [String] = []

    var startedComment = false
    var finishedComment = false

    // todo this is a dummy range, should be replaced with the
    // actual range of the comment that is being processed.
    let dummyRange = SourceRange(
      Range(uncheckedBounds: (lower: "".startIndex, upper: "".endIndex)),
      in: source
    )

    for line in lines {
      let isCommentLine =
        line
        .trimmingPrefix { $0.isWhitespace }
        .hasPrefix("///")

      if isCommentLine {
        if finishedComment {
          addComment(lines: commentLines, origin: dummyRange, target: nil)
          commentLines = []
          startedComment = false
          finishedComment = false
        }

        if !startedComment {
          startedComment = true
        }

        commentLines.append(String(line))
      } else {
        if startedComment && !finishedComment {
          finishedComment = true
        }
      }
    }

    if startedComment {
      addComment(lines: commentLines, origin: dummyRange, target: target)
    }
  }

  /// Adds a comment to the appropriate list based on its type.
  ///
  /// - Parameters:
  ///   - lines: The lines of the comment.
  ///   - target: The target index for the symbol comment, if applicable.
  private mutating func addComment(lines: [String], origin: SourceRange, target: SourceFile.Index?)
  {
    let result = commentParser.parse(commentLines: lines)
    if case .failure(let error) = result {
      diagnostics.insert(.error(error.localizedDescription, at: origin))
    }
    let info = try! result.get()

    switch info.type {
    case .fileLevel:
      guard self.fileComment == nil else {
        diagnostics.insert(
          .error("Only one file-level documentation comment is allowed.", at: origin))
        return
      }

      self.fileComment = .init(value: info, range: origin)
    case .symbol:
      guard target != nil else {
        diagnostics.insert(
          .error(
            "Documentation comment is not related to any code"
              + "entity, nor is it a file-level or section comment.",
            at: origin
          ))
        return
      }
      symbolComments[target!] = .init(value: info, range: origin)
    case .section:
      fatalError("Section comments are not supported yet")
      break
    }
  }
}
