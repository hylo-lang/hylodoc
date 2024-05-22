import Foundation
import MarkdownKit

enum MarkdownParserError: Error, CustomStringConvertible {
  case invalidComment(line: String)
  case emptySection(String)
  case improperStructure(String)

  var description: String {
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

// Custom trimming function for line processing
// In case a line has whitespaces before the slashes
extension String {
  func trimmingLeadingWhitespace() -> String {
    guard let index = firstIndex(where: { !$0.isWhitespace }) else {
      return ""
    }
    return String(self[index...])
  }
}

// Remove leading /// and check for valid syntax
func processCommentLines(_ lines: [String]) throws -> [String] {
  var processedLines = [String]()

  for line in lines {

    let newLine = line.trimmingLeadingWhitespace()

    if newLine.hasPrefix("/// ") {
      processedLines.append(String(newLine.dropFirst(4)))
    } else if newLine == "///" {
      processedLines.append("")
    } else if newLine.hasPrefix("///") {
      print("Warning: Invalid comment syntax, add a whitespace after '///'.")
      processedLines.append(String(newLine.dropFirst(3)))
    } else {
      throw MarkdownParserError.invalidComment(line: "Comment syntax is invalid at: " + line)
    }
  }

  return processedLines
}

// Data structure for parsing result
public struct MarkdownDocResult {
  var content: [Block]
  var specialSections: [SpecialSection]
}

public struct SpecialSection {
  let name: String
  var blocks: [Block]
}

// Calls Markdownkit to parse the comment block and then process result
public func parseMarkdown(from lines: [String]) throws -> MarkdownDocResult {
  let markdown = try processCommentLines(lines).joined(separator: "\n")
  let document = MarkdownParser.standard.parse(markdown)

  guard case let .document(blocks) = document else {
    throw MarkdownParserError.improperStructure(
      "Root node is not a document, it is a: " + document.debugDescription)
  }
  return try parseMarkdownHelper(blocks)
}

// Splits the parsed markdown into pre-heading blocks (summary/description) and sections
func parseMarkdownHelper(_ document: Blocks) throws -> MarkdownDocResult {
  var currentSection: SpecialSection? = nil
  var sections: [SpecialSection] = []
  var content: [Block] = []

  for block in document {
    switch block {
    case .heading(1, let text):
      if let section = currentSection {
        sections.append(section)
      }

      let headingText = text.rawDescription.trimmingCharacters(in: .whitespaces)

      guard !headingText.isEmpty else {
        throw MarkdownParserError.improperStructure("Heading has no valid text")
      }

      currentSection = SpecialSection(name: headingText, blocks: [])
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

  return MarkdownDocResult(
    content: content,
    specialSections: sections
  )
}
