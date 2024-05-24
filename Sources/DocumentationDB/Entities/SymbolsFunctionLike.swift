import MarkdownKit

/// Documentation of a free function declaration (not a method) or a static function declaration.
public struct FunctionDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDocumentation
}

/// A method declaration within a product type or trait
///
/// Note: method declarations might have multiple implementations inside, and each implementation
/// might also have additional documentation. In that case, that should be also displayed additionally.
public struct MethodDeclDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDocumentation
}

/// Documentation of a method implementation.
///
/// A method declaration might have one or more implementations inside for
/// the different access effects (let, inout, sink, etc.). Each implementation might
/// want to have its own documentation to specify the behavior of the implementation and to
/// add additional information that is only relevant to that implementation.
public struct MethodImplDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDocumentation
}

public struct CommonFunctionDocumentation {
  public let common: GeneralDescriptionFields
  public let preconditions: [Precondition]
  public let postconditions: [Postcondition]
  public let returns: ReturnsInfo?
  public let throwsInfo: ThrowsInfo?
  public let parameters: ParameterDocumentations
  public let genericParameters: GenericParameterDocumentations
}

/// Type initializer (e.g. init or memberwise init)
public struct InitializerDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
  public let preconditions: [Precondition]
  public let postconditions: [Postcondition]
  public let parameters: ParameterDocumentations
  public let genericParameters: GenericParameterDocumentations
  public let throwsInfo: ThrowsInfo?
}

/// Declaration of either a subscript or a property
public struct SubscriptDeclDocumentation: IdentifiedEntity {
  public let documentation: SubscriptCommonDocumentation
}

/// Additional documentation that is specific to a subscript implementation (let, inout, etc.)
public struct SubscriptImplDocumentation: IdentifiedEntity {
  public let documentation: SubscriptCommonDocumentation
}

public struct SubscriptCommonDocumentation {
  public let generalDescription: GeneralDescriptionFields
  public let preconditions: [Precondition]
  public let postconditions: [Postcondition]
  public let yields: YieldsInfo?
  public let throwsInfo: ThrowsInfo?
  public let parameters: ParameterDocumentations
  public let genericParameters: GenericParameterDocumentations
}

/// This is not used but the symbol still needs to be rendered in the documentation.
/// All information is already present in the declaration AST node SynthesizedFunctionDecl.
public struct SynthesizedFunctionDocumentation {}

/// Documentation of the returned value of a function or method
public enum ReturnsInfo {
  /// Used when there is one paragraph of `# Returns:` documentation.
  case always(Block)

  /// Used when the function returns different information in different cases.
  /// This can be expressed as adding list items after the `# Returns:` section header.
  case cases([Block])
}

/// Documentation of the yielded value of a subscript or property
public enum YieldsInfo {
  /// Used when there is one paragraph of `# Yields:` documentation.
  case always(Block)

  /// Used when the function returns different information in different cases.
  /// This can be expressed as adding list items after the `# Yields:` section header.
  case cases([Block])
}

/// Documentation of the behavior of a function-like when it throws an exception.
public enum ThrowsInfo {
  /// Used when there is one paragraph of `# Throws:` documentation.
  case generally(Block)

  /// Used when the function throws different exceptions in different cases and the
  /// developer wants to document these cases separately in a list form.
  case cases([Block])
}
