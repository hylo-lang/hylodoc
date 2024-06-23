import DocumentationDB
import FrontEnd
import HDCUtils
import MarkdownKit

@Diagnostify
public struct FileLevelContentBeforeSpecialSectionsWarning {}
@Diagnostify
public struct FileLevelWrongNameError {}
@Diagnostify
public struct EmptySpecialSectionWarning {}
@Diagnostify
public struct SpecialSectionMoreThanOneListWarning {}
@Diagnostify
public struct ListSpecialSectionHasNoListError {}
@Diagnostify
public struct UnexpectedSpecialSectionTitleError {}
@Diagnostify
public struct InlineSpecialSectionTitleRemoveFailureWarning {}
@Diagnostify
public struct SpecialSectionListDoesNotHaveListItemChildrenWarning {}
@Diagnostify
public struct BothInlineAndListSpecialSectionError {}
@Diagnostify
public struct ParameterSectionMissingColonWarning {}
@Diagnostify
public struct UnknownParameterInDocumentationWarning {}

public protocol SourceFileDocumentor {
  func document(
    ast: AST, translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout HDCDiagnosticSet
  ) -> GeneralDescriptionFields
}

public struct RealSourceFileDocumentor: SourceFileDocumentor {
  private let commentParser: any CommentParser
  private let markdownParser: MarkdownParser

  public init(commentParser: any CommentParser, markdownParser: MarkdownParser) {
    self.commentParser = commentParser
    self.markdownParser = markdownParser
  }

  public func document(
    ast: AST,
    translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout HDCDiagnosticSet
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
      symbolStore: symbolStore, documentedFile: documentedFile, markdownParser: markdownParser)
    ast.walk(translationUnitId, notifying: &visitor)

    symbolStore = visitor.symbolStore
    diagnostics.formUnion(visitor.diagnostics)

    // Parse the file-level documentation
    return parseFileLevelDocumentation(documentedFile: documentedFile, diagnostics: &diagnostics)
  }
}

private func parseFileLevelDocumentation(
  documentedFile: DocumentedFile, diagnostics: inout HDCDiagnosticSet
) -> GeneralDescriptionFields {
  guard let fileLevelComment = documentedFile.fileLevel else {
    return GeneralDescriptionFields(summary: nil, description: nil, seeAlso: [])
  }

  if !fileLevelComment.value.contentBeforeSections.isEmpty {
    diagnostics.insert(
      FileLevelContentBeforeSpecialSectionsWarning.warning(
        "File-level comments should not contain content before the special sections (#). Any content before # File-level is ignored.",
        at: fileLevelComment.site))
  }

  validateAllowedSpecialSections(
    allowedSections: [.fileLevel, .seeAlso],
    comment: fileLevelComment,
    diagnostics: &diagnostics
  )

  let (summary, description) = parseSummaryAndDescription(
    blocks: fileLevelComment.value.specialSections.first {
      if $0.name.lowercased() == SpecialSectionType.fileLevel.headingName { return true }
      if $0.name.lowercased() == "file-level" {  //Is this correct?
        diagnostics.insert(
          FileLevelWrongNameError.error(
            "File-level section should be named 'File-level:' (with a colon).",
            at: fileLevelComment.site)
        )
        return true
      }
      return false
    }!.blocks,
    diagnostics: &diagnostics
  )

  return GeneralDescriptionFields(
    summary: summary,
    description: description,
    seeAlso: parseSeeAlsoSection(comment: fileLevelComment, diagnostics: &diagnostics)
  )
}

private func parseSummaryAndDescription(blocks: [Block], diagnostics: inout HDCDiagnosticSet) -> (
  Block?, Block?
) {
  guard let firstBlock = blocks.first else {
    return (nil, nil)
  }

  return (.document([firstBlock]), .document(Blocks(blocks.dropFirst())))
}

private func parseSeeAlsoSection(
  comment: SourceRepresentable<LowLevelCommentInfo>, diagnostics: inout HDCDiagnosticSet
) -> [Block] {
  let seeAlsoSection = comment.value.specialSections.first {
    $0.name == SpecialSectionType.seeAlso.headingName
  }
  guard let seeAlso = seeAlsoSection else {
    return []
  }

  return parseSeeAlsoSection(section: seeAlso, site: comment.site, diagnostics: &diagnostics)
}
private func parseSeeAlsoSection(
  section: LowLevelCommentInfo.SpecialSection,
  site: SourceRange,
  diagnostics: inout HDCDiagnosticSet
) -> [Block] {
  if section.blocks.isEmpty {
    diagnostics.insert(EmptySpecialSectionWarning.warning("Empty see also section.", at: site))
    return []
  }
  if section.blocks.count > 1 {
    diagnostics.insert(
      SpecialSectionMoreThanOneListWarning.warning(
        "See also section should contain only one list.", at: site))
  }
  guard case .list(_, _, let blocks) = section.blocks.first! else {
    diagnostics.insert(
      ListSpecialSectionHasNoListError.error("See also section should contain a list.", at: site))
    return []
  }

  return Array(blocks)
}

public enum SpecialSectionType {
  case `parameter`
  case `returns`
  case `throws`
  case `precondition`
  case `postcondition`
  case `invariant`
  case `complexity`
  case `seeAlso`
  case `fileLevel`
  case `generic`
  case `yields`
  case `projects`

  public var inlineName: String {
    switch self {
    case .seeAlso:
      return "see also:"
    case .fileLevel:
      return "file-level:"  // todo improve error handling of the special section name, e.g. missing colon
    case .parameter:
      return "parameter "
    case .returns:
      return "returns: "
    case .throws:
      return "throws: "
    case .precondition:
      return "precondition: "
    case .postcondition:
      return "postcondition: "
    case .invariant:
      return "invariant: "
    case .complexity:
      return "complexity: "
    case .projects:
      return "projects: "
    case .generic:
      return "generic "
    case .yields:
      return "yields: "
    }
  }

  public var headingName: String {
    switch self {
    case .seeAlso:
      return "see also:"
    case .fileLevel:
      return "file-level:"  // todo improve error handling of the special section name, e.g. missing colon
    case .parameter:
      return "parameters:"
    case .returns:
      return "returns:"
    case .throws:
      return "throws:"
    case .precondition:
      return "preconditions:"
    case .postcondition:
      return "postconditions:"
    case .invariant:
      return "invariants:"
    case .complexity:
      return "complexity:"
    case .projects:
      return "projects:"
    case .generic:
      return "generics:"
    case .yields:
      return "yields:"
    }
  }
}

public enum SpecialSectionPreset {
  case `default`
  case `function`
  case `method`
  case `methodImpl`
  case `subscriptImpl`
  case `subscript`
  case `initializer`
  case `withInvariants`
  case `withInvariantsAndGenerics`

  public var allowedSections: Set<SpecialSectionType> {
    switch self {
    case .default:
      return [.seeAlso]
    case .function, .method:
      return [
        .seeAlso, .parameter, .returns, .throws, .precondition, .postcondition, .complexity,
        .generic,
      ]
    case .withInvariants:
      return [.seeAlso, .invariant]
    case .withInvariantsAndGenerics:
      return [.seeAlso, .invariant, .generic]
    case .subscript:
      return [
        .seeAlso, .parameter, .throws, .precondition, .postcondition, .complexity, .generic,
        .yields, .projects,
      ]
    case .subscriptImpl:
      return [
        .seeAlso, .throws, .precondition, .postcondition, .complexity, .yields, .projects,
      ]
    case .methodImpl:
      return [
        .seeAlso, .throws, .precondition, .postcondition, .returns,
      ]
    case .initializer:
      return [
        .seeAlso, .parameter, .throws, .precondition, .postcondition, .complexity, .generic,
      ]
    }
  }
}

private func validateAllowedSpecialSections(
  allowedSections: Set<SpecialSectionType>? = nil,
  preset: SpecialSectionPreset? = nil,
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet
) {
  let allowedSectionTitles: [String]

  if let allowedSections = allowedSections {
    allowedSectionTitles = allowedSections.flatMap { section in
      [section.inlineName.lowercased(), section.headingName.lowercased()]
    }
  } else if let preset = preset {
    allowedSectionTitles = preset.allowedSections.flatMap { section in
      [section.inlineName.lowercased(), section.headingName.lowercased()]
    }
  } else {
    allowedSectionTitles = []
  }

  for section in comment.value.specialSections {
    if !allowedSectionTitles.contains(where: { section.name.lowercased().starts(with: $0) }) {
      diagnostics.insert(
        UnexpectedSpecialSectionTitleError.error(
          "Unexpected special section heading '\(section.name.lowercased())'.\nApplicable section titles are: \(allowedSectionTitles.descriptions())",
          at: comment.site)
      )
    }
  }
}

public struct DummySourceFileDocumentor: SourceFileDocumentor {
  public func document(
    ast: AST, translationUnitId: TranslationUnit.ID, into symbolStore: inout SymbolDocStore,
    diagnostics: inout HDCDiagnosticSet
  ) -> GeneralDescriptionFields {
    return .init(summary: nil, description: nil, seeAlso: [])
  }
}

private struct SymbolDocumenterASTVisitor: ASTWalkObserver {
  private let documentedFile: DocumentedFile
  public private(set) var symbolStore: SymbolDocStore
  public private(set) var diagnostics: HDCDiagnosticSet

  private let markdownParser: MarkdownParser

  init(symbolStore: SymbolDocStore, documentedFile: DocumentedFile, markdownParser: MarkdownParser)
  {
    self.symbolStore = symbolStore
    self.documentedFile = documentedFile
    self.diagnostics = HDCDiagnosticSet()
    self.markdownParser = markdownParser
  }

  //TODO: in the future make an array of (initializers, database) for the basic types
  // that only have the common description and just iterate using the array, avoids a lot of repetition
  // also one array for types that have common desc + invariants, etc.
  mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
    if let d = TypeAliasDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .default,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.typeAliasDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(comment: symbolComment, diagnostics: &diagnostics)
          ),
          for: d
        )
      }
    } else if let d = AssociatedTypeDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .default,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.associatedTypeDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(comment: symbolComment, diagnostics: &diagnostics)
          ),
          for: d
        )
      }
    } else if let d = AssociatedValueDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .default,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.associatedValueDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(comment: symbolComment, diagnostics: &diagnostics)
          ),
          for: d
        )
      }
    } else if let d = OperatorDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .default,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.operatorDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(comment: symbolComment, diagnostics: &diagnostics)
          ),
          for: d
        )
      }
    } else if let d = BindingDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .withInvariants,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.bindingDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(
              comment: symbolComment, diagnostics: &diagnostics),
            invariants: parseSpecialSection(
              type: .invariant, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Invariant.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = TraitDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {
        validateAllowedSpecialSections(
          preset: .withInvariants,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.traitDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(
              comment: symbolComment, diagnostics: &diagnostics),
            invariants: parseSpecialSection(
              type: .invariant, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Invariant.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = ProductTypeDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .withInvariantsAndGenerics,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.productTypeDocs.insert(
          .init(
            common: symbolGeneralDescriptionMaker(
              comment: symbolComment, diagnostics: &diagnostics),
            invariants: parseSpecialSection(
              type: .invariant, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Invariant.init(description:), markdownParser: markdownParser),
            genericParameters: makeJustGenericParameters(
              comment: symbolComment, diagnostics: &diagnostics, astID: AnyDeclID(d), ast: ast)
          ),
          for: d
        )
      }
    } else if let d = FunctionDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .function,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.functionDocs.insert(
          .init(
            documentation: commonFuncDeclDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics,
              astID: AnyDeclID(d),
              ast: ast
            ),
            returns: parseSpecialSection(
              type: .returns, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Returns.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = MethodDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .method,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.methodDeclDocs.insert(
          .init(
            documentation: commonFuncDeclDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics,
              astID: AnyDeclID(d),
              ast: ast
            ),
            returns: parseSpecialSection(
              type: .returns, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Returns.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = MethodImpl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .methodImpl,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.methodImplDocs.insert(
          .init(
            documentation: commonFuncDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics
            ),
            returns: parseSpecialSection(
              type: .returns, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Returns.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = SubscriptDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .subscript,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.subscriptDeclDocs.insert(
          .init(
            documentation: commonFuncDeclDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics,
              astID: AnyDeclID(d),
              ast: ast
            ),
            yields: parseSpecialSection(
              type: .yields, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Yields.init(description:), markdownParser: markdownParser),
            projectsInfo: parseSpecialSection(
              type: .projects, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Projects.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = SubscriptImpl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .subscriptImpl,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.subscriptImplDocs.insert(
          .init(
            documentation: commonFuncDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics
            ),
            yields: parseSpecialSection(
              type: .yields, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Yields.init(description:), markdownParser: markdownParser),
            projectsInfo: parseSpecialSection(
              type: .projects, comment: symbolComment, diagnostics: &diagnostics,
              constructor: Projects.init(description:), markdownParser: markdownParser)
          ),
          for: d
        )
      }
    } else if let d = InitializerDecl.ID(id) {
      if let symbolComment = documentedFile.symbolComments[ast[d].site.startIndex] {

        validateAllowedSpecialSections(
          preset: .initializer,
          comment: symbolComment,
          diagnostics: &diagnostics
        )

        let _ = symbolStore.initializerDocs.insert(
          .init(
            documentation: commonFuncDeclDocMaker(
              comment: symbolComment,
              diagnostics: &diagnostics,
              astID: AnyDeclID(d),
              ast: ast
            )
          ),
          for: d
        )
      }
    }
    return true
  }

  // Creates the general description for documentations
  private func symbolGeneralDescriptionMaker(
    comment: SourceRepresentable<LowLevelCommentInfo>,
    diagnostics: inout HDCDiagnosticSet
  ) -> GeneralDescriptionFields {
    let (summary, description) = parseSummaryAndDescription(
      blocks: comment.value.contentBeforeSections,
      diagnostics: &diagnostics
    )

    return GeneralDescriptionFields.init(
      summary: summary,
      description: description,
      seeAlso: parseSeeAlsoSection(comment: comment, diagnostics: &diagnostics)
    )
  }

  // Creates the general function documentation fields
  private func commonFuncDocMaker(
    comment: SourceRepresentable<LowLevelCommentInfo>,
    diagnostics: inout HDCDiagnosticSet
  ) -> CommonFunctionLikeDocumentation {
    return CommonFunctionLikeDocumentation.init(
      common: symbolGeneralDescriptionMaker(comment: comment, diagnostics: &diagnostics),
      preconditions: parseSpecialSection(
        type: .precondition, comment: comment, diagnostics: &diagnostics,
        constructor: Precondition.init(description:), markdownParser: markdownParser),
      postconditions: parseSpecialSection(
        type: .postcondition, comment: comment, diagnostics: &diagnostics,
        constructor: Postcondition.init(description:), markdownParser: markdownParser),
      throwsInfo: parseSpecialSection(
        type: .throws, comment: comment, diagnostics: &diagnostics,
        constructor: Throws.init(description:), markdownParser: markdownParser),
      complexityInfo: parseSpecialSection(
        type: .complexity, comment: comment, diagnostics: &diagnostics,
        constructor: Complexity.init(description:), markdownParser: markdownParser)
    )
  }

  // Creates the general function declaration fields
  private func commonFuncDeclDocMaker(
    comment: SourceRepresentable<LowLevelCommentInfo>,
    diagnostics: inout HDCDiagnosticSet,
    astID: AnyDeclID,
    ast: AST
  ) -> CommonFunctionDeclLikeDocumentation {

    let (parameters, genericParameters) = makeParameters(
      comment: comment, diagnostics: &diagnostics, astID: astID, ast: ast)

    return CommonFunctionDeclLikeDocumentation.init(
      common: commonFuncDocMaker(comment: comment, diagnostics: &diagnostics),
      parameters: parameters,
      genericParameters: genericParameters
    )
  }
}

// Removes a section title from an inline special section
//
// "Invariant x and y must be positive" -> "x and y must be positive"
private func removeSectionTitleInline(
  title: SpecialSectionType,
  text: String,
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet
) -> String {
  if text.lowercased().hasPrefix(title.inlineName) {
    return String(text.dropFirst(title.inlineName.count))
  } else {
    diagnostics.insert(
      InlineSpecialSectionTitleRemoveFailureWarning.warning(
        "Unable to remove title from inline section with text \(text)", at: comment.site))
    return text
  }
}

// Generic function that parses normal special sections into their respective fields in the DB
//  (normal means non parameters or generics)
//
// # Parameters:
//  - type: The special section to parse
//  - comment: The comment to parse
//  - constructor: the constructor of the type
// # Returns array of of the identified DB entities
private func parseSpecialSection<T>(
  type: SpecialSectionType,
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet,
  constructor: (Block) -> T,
  markdownParser: MarkdownParser
) -> [T] {
  var parsedSections: [T] = []

  let inlineSections = comment.value.specialSections.filter {
    $0.name.lowercased().starts(with: type.inlineName)
  }

  if !inlineSections.isEmpty {
    for inlineSection in inlineSections {
      let descriptionText = removeSectionTitleInline(
        title: type, text: inlineSection.name,
        comment: comment, diagnostics: &diagnostics
      )
      parsedSections.append(constructor(markdownParser.parse(descriptionText)))
    }
  } else {
    let blockSection = comment.value.specialSections.first {
      $0.name.lowercased() == type.headingName
    }

    if let block = blockSection {
      if block.blocks.isEmpty {
        diagnostics.insert(
          EmptySpecialSectionWarning.warning(
            "Empty \(type.headingName)s section.", at: comment.site))
      } else if block.blocks.count > 1 {
        diagnostics.insert(
          SpecialSectionMoreThanOneListWarning.warning(
            "\(type.headingName.capitalized)s section should contain only one list.",
            at: comment.site))
      } else if case .list(_, _, let blocks) = block.blocks.first! {
        for block in blocks {
          if case .listItem(_, _, let itemBlocks) = block {
            parsedSections.append(constructor(Block.document(itemBlocks)))
          } else {
            diagnostics.insert(
              SpecialSectionListDoesNotHaveListItemChildrenWarning.warning(
                "Unexpected block type in \(type.headingName)s list.", at: comment.site))
          }
        }
      } else {
        diagnostics.insert(
          ListSpecialSectionHasNoListError.error(
            "\(type.headingName.capitalized)s section should contain a list.", at: comment.site))
      }
    }
  }

  return parsedSections
}

// Creates the parameter maps for function documentation
//
// In order to validate the documented parameters they need to be
// retrieved from the ast. This method gets all of the parameters and
// generics from the ast for the given symbol ID and creates two maps
// of the parameter IDs and their string names.
//
// # Returns:
//  - ([ParameterDecl.ID: ParameterDocumentation], [GenericParameterDecl.ID: GenericParameterDocumentation])
private func makeParameters(
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet,
  astID: AnyDeclID,
  ast: AST
) -> (ParameterDocumentations, GenericParameterDocumentations) {
  var parameterDocs: ParameterDocumentations = [:]
  var genericParameterDocs: GenericParameterDocumentations = [:]

  let paramDecls = ast.runtimeParameters(of: astID) ?? []
  let genericParamDecls = ast.genericParameters(introducedBy: astID)

  let paramMap = paramDecls.reduce(into: [String: ParameterDecl.ID]()) { (dict, paramID) in
    dict[ast[paramID].identifier.value] = paramID
  }

  let genericParamMap = genericParamDecls.reduce(into: [String: GenericParameterDecl.ID]()) {
    (dict, paramID) in
    dict[ast[paramID].identifier.value] = paramID
  }

  if !paramDecls.isEmpty {
    parameterDocs = createParameterDocs(
      type: .parameter,
      paramMap: paramMap,
      comment: comment,
      diagnostics: &diagnostics,
      constructor: { x in x }
    )
  }

  if !genericParamDecls.isEmpty {
    genericParameterDocs = createParameterDocs(
      type: .generic,
      paramMap: genericParamMap,
      comment: comment,
      diagnostics: &diagnostics,
      constructor: { x in x }
    )
  }

  return (parameterDocs, genericParameterDocs)
}

/// Creates generic parameter docs
private func makeJustGenericParameters(
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet,
  astID: AnyDeclID,
  ast: AST
) -> GenericParameterDocumentations {
  var genericParameterDocs: GenericParameterDocumentations = [:]

  let genericParamDecls = ast.genericParameters(introducedBy: astID)

  let genericParamMap = genericParamDecls.reduce(into: [String: GenericParameterDecl.ID]()) {
    (dict, paramID) in
    dict[ast[paramID].identifier.value] = paramID
  }

  if !genericParamDecls.isEmpty {
    genericParameterDocs = createParameterDocs(
      type: .generic,
      paramMap: genericParamMap,
      comment: comment,
      diagnostics: &diagnostics,
      constructor: { x in x }
    )
  }

  return genericParameterDocs
}

// This method takes the comment and the identified parameters in the AST and validates and creates the docs.
//
// Parameter docstrings in the symbol comment
private func createParameterDocs<T, U: NodeIDProtocol>(
  type: SpecialSectionType,
  paramMap: [String: U],
  comment: SourceRepresentable<LowLevelCommentInfo>,
  diagnostics: inout HDCDiagnosticSet,
  constructor: (Block) -> T
) -> [U: T] {
  var docs: [U: T] = [:]

  let inlineParameters = comment.value.specialSections.filter {
    $0.name.lowercased().starts(with: type.inlineName) && $0.blocks.isEmpty
  }

  let parametersSection = comment.value.specialSections.first {
    $0.name.lowercased() == type.headingName
  }

  if !inlineParameters.isEmpty && parametersSection != nil {
    diagnostics.insert(
      BothInlineAndListSpecialSectionError.error(
        "Both inline \(type.inlineName)s and a \(type.headingName.capitalized) section are present. Use only one.",
        at: comment.site))
    return docs
  }

  for inlineParameter in inlineParameters {
    let paramText = inlineParameter.name.dropFirst(type.inlineName.capitalized.count)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if let (paramID, doc) = createParameterDocsHelper(
      fullText: paramText,
      type: type,
      paramMap: paramMap,
      constructor: constructor,
      diagnostics: &diagnostics,
      comment: comment
    ) {
      docs[paramID] = doc
    }
  }

  if let section = parametersSection {
    if section.blocks.isEmpty {
      diagnostics.insert(
        EmptySpecialSectionWarning.warning(
          "Empty \(type.headingName.capitalized) section.", at: comment.site))
    } else if section.blocks.count > 1 {
      diagnostics.insert(
        SpecialSectionMoreThanOneListWarning.warning(
          "\(type.headingName.capitalized) section should contain only one list.", at: comment.site)
      )
    } else if case .list(_, _, let blocks) = section.blocks.first! {
      for block in blocks {
        if case .listItem(_, _, let itemBlocks) = block, itemBlocks.count == 1,
          case .paragraph(let text) = itemBlocks.first!
        {
          let fullText = text.description
          if let (paramID, doc) = createParameterDocsHelper(
            fullText: fullText,
            type: type,
            paramMap: paramMap,
            constructor: constructor,
            diagnostics: &diagnostics,
            comment: comment
          ) {
            docs[paramID] = doc
          }
        } else {
          diagnostics.insert(
            SpecialSectionListDoesNotHaveListItemChildrenWarning.warning(
              "Unexpected block type in \(type.headingName) list. Should be one paragraph",
              at: comment.site))
        }
      }
    }
  }

  return docs
}

private func createParameterDocsHelper<U: NodeIDProtocol, T>(
  fullText: String,
  type: SpecialSectionType,
  paramMap: [String: U],
  constructor: (Block) -> T,
  diagnostics: inout HDCDiagnosticSet,
  comment: SourceRepresentable<LowLevelCommentInfo>
) -> (paramID: U, doc: T)? {
  guard let colonIndex = fullText.firstIndex(of: ":") else {
    diagnostics.insert(
      ParameterSectionMissingColonWarning.warning(
        "\(type.inlineName.capitalized) format is incorrect, missing colon.", at: comment.site))
    return nil
  }

  let paramName = String(fullText[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
  let descriptionText = String(fullText[fullText.index(after: colonIndex)...]).trimmingCharacters(
    in: .whitespacesAndNewlines)

  guard let paramID = paramMap[paramName] else {
    diagnostics.insert(
      UnknownParameterInDocumentationWarning.warning(
        "\(type.inlineName.capitalized) \(paramName) not found in declaration.", at: comment.site))
    return nil
  }

  let descriptionBlock = MarkdownParser.standard.parse(descriptionText)
  let doc = constructor(descriptionBlock)
  return (paramID, doc)
}
