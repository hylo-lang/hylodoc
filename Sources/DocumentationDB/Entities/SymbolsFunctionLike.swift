import MarkdownKit

//Structs

public struct CommonFunctionLikeDocumentation {
  public let common: GeneralDescriptionFields
  public let preconditions: [Precondition]
  public let postconditions: [Postcondition]
  public let throwsInfo: [Throws]

  public init(
    common: GeneralDescriptionFields,
    preconditions: [Precondition],
    postconditions: [Postcondition],
    throwsInfo: [Throws]
  ) {
    self.common = common
    self.preconditions = preconditions
    self.postconditions = postconditions
    self.throwsInfo = throwsInfo
  }
}

public struct CommonFunctionDeclLikeDocumentation {
  public let common: CommonFunctionLikeDocumentation
  public let parameters: ParameterDocumentations
  public let genericParameters: GenericParameterDocumentations

  public init(
    common: CommonFunctionLikeDocumentation,
    parameters: ParameterDocumentations,
    genericParameters: GenericParameterDocumentations
  ) {
    self.common = common
    self.parameters = parameters
    self.genericParameters = genericParameters
  }
}

/// Documentation of a free function declaration (not a method) or a static function declaration.
public struct FunctionDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDeclLikeDocumentation
  public let returns: [Returns]

  public init(
    documentation: CommonFunctionDeclLikeDocumentation,
    returns: [Returns]
  ) {
    self.documentation = documentation
    self.returns = returns
  }
}

/// A method declaration within a product type or trait
///
/// Note: method declarations might have multiple implementations inside, and each implementation
/// might also have additional documentation. In that case, that should be also displayed additionally.
public struct MethodDeclDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDeclLikeDocumentation
  public let returns: [Returns]

  public init(
    documentation: CommonFunctionDeclLikeDocumentation,
    returns: [Returns]
  ) {
    self.documentation = documentation
    self.returns = returns
  }
}

/// Documentation of a method implementation.
///
/// A method declaration might have one or more implementations inside for
/// the different access effects (let, inout, sink, etc.). Each implementation might
/// want to have its own documentation to specify the behavior of the implementation and to
/// add additional information that is only relevant to that implementation.
public struct MethodImplDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionLikeDocumentation
  public let returns: [Returns]

  public init(
    documentation: CommonFunctionLikeDocumentation,
    returns: [Returns]
  ) {
    self.documentation = documentation
    self.returns = returns
  }
}

/// Type initializer (e.g. init or memberwise init)
public struct InitializerDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDeclLikeDocumentation

  public init(documentation: CommonFunctionDeclLikeDocumentation) {
    self.documentation = documentation
  }
}

/// Declaration of either a subscript or a property
public struct SubscriptDeclDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionDeclLikeDocumentation
  public let yields: [Yields]

  public init(
    documentation: CommonFunctionDeclLikeDocumentation,
    yields: [Yields]
  ) {
    self.documentation = documentation
    self.yields = yields
  }
}

/// Additional documentation that is specific to a subscript implementation (let, inout, etc.)
public struct SubscriptImplDocumentation: IdentifiedEntity {
  public let documentation: CommonFunctionLikeDocumentation
  public let yields: [Yields]

  public init(
    documentation: CommonFunctionLikeDocumentation,
    yields: [Yields]
  ) {
    self.documentation = documentation
    self.yields = yields
  }
}

/// This is not used but the symbol still needs to be rendered in the documentation.
/// All information is already present in the declaration AST node SynthesizedFunctionDecl.
public struct SynthesizedFunctionDocumentation {}

public struct Returns {
  public let description: Block

  public init(description: Block) {
    self.description = description
  }
}

public struct Yields {
  public let description: Block

  public init(description: Block) {
    self.description = description
  }
}

public struct Throws {
  public let description: Block

  public init(description: Block) {
    self.description = description
  }
}
