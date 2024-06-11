import Foundation
import MarkdownKit

public struct LowLevelCommentInfo {
  /// Markdown content before the special sections
  public let contentBeforeSections: [Block]
  public let specialSections: [SpecialSection]
  public var type: CommentType {
    guard let title = specialSections.first?.name.split(separator: ":").first else {
      return .symbol
    }

    switch title.lowercased() {
    case "file-level":
      return .fileLevel
    case "section":
      return .section
    default:
      return .symbol
    }
  }

  public init(
    contentBeforeSections: [Block],
    specialSections: [SpecialSection]
  ) {
    self.contentBeforeSections = contentBeforeSections
    self.specialSections = specialSections
  }

  /// A Special section inside a documentation comment is a first-level heading
  /// and the content after it.
  public struct SpecialSection {
    let name: String
    var blocks: [Block]
  }

  /// The type of the documentation comment
  public enum CommentType {
    /// The documentation associated with a file.
    ///
    /// Start the comment with `/// # File-level:`
    /// Max 1 is allowed per file.
    case fileLevel

    /// Documentation associated with an API element.
    case symbol

    /// Divides the file into sections.
    ///
    /// Start the comment with `/// # Section:`
    /// Each section must have a title and optionally some summary and description
    case section
  }
}

public protocol LowLevelCommentParser {
  associatedtype ParsingError: Error, Equatable
  func parse(commentLines: [String]) -> Result<LowLevelCommentInfo, ParsingError>
}

public enum MarkdownParserError: Error, CustomStringConvertible {
  case invalidComment(line: String)
  case emptySection(String)
  case improperStructure(String)

  public var description: String {
    switch self {
    case .invalidComment(let line):
      return "Invalid comment syntax: \(line)"
    case .emptySection(let section):
      return "The section \(section) is empty. "
    case .improperStructure(let text):
      return text
    }
  }
}

public struct RealLowLevelCommentParser: LowLevelCommentParser {
  public init() {}

  public enum ParsingError: Error, Equatable {
    case missingWhitespace(inLine: String)
    case emptySpecialSectionHeading
  }

  // Calls Markdownkit to parse the comment block and then process result
  public func parse(commentLines: [String]) -> Result<LowLevelCommentInfo, ParsingError> {
    stripLeadingDocSlashes(commentLines: commentLines)
      .map { $0.joined(separator: "\n") }
      .map { MarkdownParser.standard.parse($0) }
      .flatMap { markdownDoc in
        guard case let .document(blocks) = markdownDoc else {
          fatalError(
            "The underlying library failed to parse the markdown into a document. Result: \n\(markdownDoc.debugDescription)"
          )
        }
        return parse(mdBlocks: blocks)
      }
  }

  /// Removes leading `/// ` from the comment lines (including the first space after `///`).
  ///
  /// - Parameter lines: The lines of the comment block
  /// - Returns: The lines without leading `/// `.
  /// - Preconditions:
  ///   - Lines must start with `///` after the leading whitespaces.
  func stripLeadingDocSlashes(commentLines: [String]) -> Result<[Substring], ParsingError> {
    commentLines.map { line in
      let trimmedLine = line.trimmingPrefix { $0.isWhitespace }
      precondition(
        trimmedLine.starts(with: "///"),
        "The comment line must start with '///': \(line)"
      )

      let withoutSlashes = trimmedLine.dropFirst(3)

      if withoutSlashes.isEmpty {
        return .success(withoutSlashes)
      }

      guard withoutSlashes.first == " " else {
        return .failure(.missingWhitespace(inLine: line))
      }
      return .success(withoutSlashes.dropFirst())
    }
    .collectResults()
  }

  // Splits the parsed markdown into pre-heading blocks (summary/description) and sections
  func parse(mdBlocks document: Blocks) -> Result<LowLevelCommentInfo, ParsingError> {
    var currentSection: LowLevelCommentInfo.SpecialSection? = nil
    var sections: [LowLevelCommentInfo.SpecialSection] = []
    var content: [Block] = []

    for block in document {
      switch block {
      case .heading(1, let text):
        if let section = currentSection {
          sections.append(section)
        }

        let headingText = text.description.trimmingCharacters(in: .whitespaces)

        guard !headingText.isEmpty else {
          return .failure(.emptySpecialSectionHeading)
        }

        currentSection = LowLevelCommentInfo.SpecialSection(name: headingText, blocks: [])
      default:
        if var section = currentSection {
          section.blocks.append(block)
          currentSection = section
        } else {
          content.append(block)
        }
      }
    }

    if let section = currentSection {
      sections.append(section)
    }

    return .success(
      LowLevelCommentInfo(
        contentBeforeSections: content,
        specialSections: sections
      )
    )
  }
}
