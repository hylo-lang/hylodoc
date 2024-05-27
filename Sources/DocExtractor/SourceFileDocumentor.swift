import DocumentationDB
import FrontEnd
import MarkdownKit

public protocol SourceFileDocumentor {
  func document(
    ast: AST, translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout DiagnosticSet
  ) -> GeneralDescriptionFields
}

public struct RealSourceFileDocumentor<CommentParserT: CommentParser>: SourceFileDocumentor {
  private let commentParser: CommentParserT

  public init(commentParser: CommentParserT) {
    self.commentParser = commentParser
  }

  public func document(
    ast: AST,
    translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout DiagnosticSet
  )
    -> GeneralDescriptionFields
  {
    // Parse the documentation comments of the source file
    guard
      let documentedFile = commentParser.parse(
        sourceFile: ast[translationUnitId].site.file,
        diagnostics: &diagnostics)
    else {
      return GeneralDescriptionFields(summary: nil, description: nil, seeAlso: [])
    }

    // Traverse the AST to collect symbol documentation

    var visitor = SymbolDocumenterASTVisitor(
      symbolStore: symbolStore, documentedFile: documentedFile)
    ast.walk(translationUnitId, notifying: &visitor)

    symbolStore = visitor.symbolStore
    diagnostics.formUnion(visitor.diagnostics)

    // Parse the file-level documentation
    return parseFileLevelDocumentation(documentedFile: documentedFile, diagnostics: &diagnostics)
  }
}

private func parseFileLevelDocumentation(
  documentedFile: DocumentedFile, diagnostics: inout DiagnosticSet
) -> GeneralDescriptionFields {
  guard let fileLevelComment = documentedFile.fileLevel else {
    return GeneralDescriptionFields(summary: nil, description: nil, seeAlso: [])
  }

  if !fileLevelComment.value.contentBeforeSections.isEmpty {
    diagnostics.insert(
      .warning(
        "File-level comments should not contain content before the special sections (#). Any content before # File-level is ignored.",
        at: fileLevelComment.site))
  }

  validateAllowedSpecialSections(
    allowedSections: [.fileLevel, .seeAlso,],
    comment: fileLevelComment,
    diagnostics: &diagnostics
  )

  let (summary, description) = parseSummaryAndDescription(
    blocks: fileLevelComment.value.specialSections.first {
      $0.name.lowercased() == SpecialSectionType.fileLevel.name
    }!.blocks,
    diagnostics: &diagnostics
  )

  return GeneralDescriptionFields(
    summary: summary,
    description: description,
    seeAlso: parseSeeAlsoSection(comment: fileLevelComment, diagnostics: &diagnostics)
  )
}

private func parseSummaryAndDescription(blocks: [Block], diagnostics: inout DiagnosticSet) -> (
  Block?, Block?
) {
  guard let firstBlock = blocks.first else {
    return (nil, nil)
  }

  return (.document([firstBlock]), .document(Blocks(blocks.dropFirst())))
}

private func parseSeeAlsoSection(
  comment: SourceRepresentable<LowLevelCommentInfo>, diagnostics: inout DiagnosticSet
) -> [Block] {
  let seeAlsoSection = comment.value.specialSections.first {
    $0.name == SpecialSectionType.seeAlso.name
  }
  guard let seeAlso = seeAlsoSection else {
    return []
  }

  return parseSeeAlsoSection(section: seeAlso, site: comment.site, diagnostics: &diagnostics)
}
private func parseSeeAlsoSection(
  section: LowLevelCommentInfo.SpecialSection,
  site: SourceRange,
  diagnostics: inout DiagnosticSet
) -> [Block] {
  if section.blocks.isEmpty {
    diagnostics.insert(.warning("Empty see also section.", at: site))
    return []
  }
  if section.blocks.count > 1 {
    diagnostics.insert(.warning("See also section should contain only one list.", at: site))
  }
  guard case .list(_, _, let blocks) = section.blocks.first! else {
    diagnostics.insert(.error("See also section should contain a list.", at: site))
    return []
  }

  return Array(blocks)
}

public enum SpecialSectionType {
  // todo add these when extending the parser, possibly dealing with plurals somehow
  // case `parameters`
  // case `returns`
  // case `throws`
  // case `precondition`
  // case `preconditions`
  // case `postcondition`
  // case `postconditions`
  // case `invariant`
  // case `invariants`
  // case `complexity`
  case `seeAlso`
  case `fileLevel`

  public var name: String {
    switch self {
    case .seeAlso:
      return "see also:"
    case .fileLevel:
      return "file-level:" // todo improve error handling of the special section name, e.g. missing colon
    }
  }
}

private func validateAllowedSpecialSections(
  allowedSections: Set<SpecialSectionType>, comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout DiagnosticSet
) {
  let allowedSectionTitles = allowedSections.map { $0.name.lowercased() }
  for section in comment.value.specialSections {
    if !allowedSectionTitles.contains(section.name.lowercased()) {
      diagnostics.insert(
        .error(
          "Unexpected special section heading '\(section.name.lowercased())'. Allowed section titles are: \(allowedSectionTitles)",
          at: comment.site)
      )
    }
  }
}

public struct DummySourceFileDocumentor: SourceFileDocumentor {
  public func document(
    ast: AST, translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout DiagnosticSet
  ) -> GeneralDescriptionFields {
    return .init(summary: nil, description: nil, seeAlso: [])
  }
}

private struct SymbolDocumenterASTVisitor: ASTWalkObserver {
  private let documentedFile: DocumentedFile
  public private(set) var symbolStore: SymbolDocStore
  public private(set) var diagnostics: DiagnosticSet

  init(symbolStore: SymbolDocStore, documentedFile: DocumentedFile) {
    self.symbolStore = symbolStore
    self.documentedFile = documentedFile
    self.diagnostics = DiagnosticSet()
  }

  mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
    if let d = TypeAliasDecl.ID(id) {
      guard let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] else {
        return false
      }

      let (summary, description) = parseSummaryAndDescription(
        blocks: symbolComment.value.contentBeforeSections,
        diagnostics: &diagnostics
      )

      validateAllowedSpecialSections(
        allowedSections: [.seeAlso],
        comment: symbolComment,
        diagnostics: &diagnostics
      )

      let _ = symbolStore.typeAliasDocs.insert(
        .init(
          common: GeneralDescriptionFields(
            summary: summary,
            description: description,
            seeAlso: parseSeeAlsoSection(comment: symbolComment, diagnostics: &diagnostics)
          )
        ),
        for: d
      )
    }

    return true
  }
}
