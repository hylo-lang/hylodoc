/// # File-Level
/// This file contains the data stored about symbols in the documentation database.

import FrontEnd

/// Description fields that are common to all kinds of symbol documentation entities.
public struct GeneralDescriptionFields {
  public let summary: AnyMarkdownNodeID?
  public let description: AnyMarkdownNodeID?
  public let seeAlso: [AnyMarkdownNodeID] // probably a link but it can also be just a text referring to something
}

/// Documentation of a typealias declaration
public struct TypeAliasDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
}

public struct Invariant {
  public let description: AnyMarkdownNodeID
}
public struct Precondition {
  public let description: AnyMarkdownNodeID
}
public struct Postcondition {
  public let description: AnyMarkdownNodeID
}


public struct GenericParameterDocumentation {
  public let description: AnyMarkdownNodeID
}

/// A map that associates each generic parameter declaration with its documentation.
public typealias GenericParameterDocumentations = [GenericParameterDecl.ID : GenericParameterDocumentation]

public struct ParameterDocumentation {
  public let description: AnyMarkdownNodeID
}

/// A map that associates each parameter declaration with its documentation.
public typealias ParameterDocumentations = [ParameterDecl.ID : ParameterDocumentation]


/// A collection of documentation information for symbols, organized by symbol kind.
public struct SymbolStore {
  public var associatedTypeDocs: AdaptedEntityStore<AssociatedTypeDecl> = .init()
  public var associatedValueDocs: AdaptedEntityStore<AssociatedValueDecl> = .init()
  public var TypeAliasDocs: AdaptedEntityStore<TypeAliasDecl> = .init()
  public var BindingDocs: AdaptedEntityStore<BindingDecl> = .init()
  public var operatorDocs: AdaptedEntityStore<OperatorDecl> = .init()

  public var functionDocs: AdaptedEntityStore<FunctionDecl> = .init()
  public var methodDeclDocs: AdaptedEntityStore<MethodDecl> = .init()
  public var methodImplDocs: AdaptedEntityStore<MethodImpl> = .init()
  public var subscriptDeclDocs: AdaptedEntityStore<SubscriptDecl> = .init()
  public var subscriptImplDocs: AdaptedEntityStore<SubscriptImpl> = .init()
  public var initializerDocs: AdaptedEntityStore<InitializerDecl> = .init()

  public var fileLevelDocs: AdaptedEntityStore<TranslationUnit> = .init()
  public var traitDocs: AdaptedEntityStore<TraitDecl> = .init()
  public var productTypeDocs: AdaptedEntityStore<ProductTypeDecl> = .init()
}