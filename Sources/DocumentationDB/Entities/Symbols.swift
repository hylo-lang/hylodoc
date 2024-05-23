/// # File-Level
/// This file contains the data stored about symbols in the documentation database.

import FrontEnd
import MarkdownKit

/// Description fields that are common to all kinds of symbol documentation entities.
public struct GeneralDescriptionFields : Equatable {
  public let summary: Block?
  public let description: Block?
  public let seeAlso: [Block] // probably a link but it can also be just a text referring to something

  public init(summary: Block?, description: Block?, seeAlso: [Block]) {
    self.summary = summary
    self.description = description
    self.seeAlso = seeAlso
  }
}

/// Documentation of a typealias declaration
public struct TypeAliasDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
}

public struct Invariant {
  public let description: Block
}
public struct Precondition {
  public let description: Block
}
public struct Postcondition {
  public let description: Block
}


public struct GenericParameterDocumentation {
  public let description: Block
}

/// A map that associates each generic parameter declaration with its documentation.
public typealias GenericParameterDocumentations = [GenericParameterDecl.ID : GenericParameterDocumentation]

public struct ParameterDocumentation {
  public let description: Block
}

/// A map that associates each parameter declaration with its documentation.
public typealias ParameterDocumentations = [ParameterDecl.ID : ParameterDocumentation]


/// A collection of documentation information for symbols, organized by symbol kind.
public struct SymbolDocStore {
  public var associatedTypeDocs: AdaptedEntityStore<AssociatedTypeDecl, AssociatedTypeDocumentation> = .init()
  public var associatedValueDocs: AdaptedEntityStore<AssociatedValueDecl, AssociatedValueDocumentation> = .init()
  public var TypeAliasDocs: AdaptedEntityStore<TypeAliasDecl, TypeAliasDocumentation> = .init()
  public var BindingDocs: AdaptedEntityStore<BindingDecl, BindingDocumentation> = .init()
  public var operatorDocs: AdaptedEntityStore<OperatorDecl, OperatorDocumentation> = .init()

  public var functionDocs: AdaptedEntityStore<FunctionDecl, FunctionDocumentation> = .init()
  public var methodDeclDocs: AdaptedEntityStore<MethodDecl, MethodDeclDocumentation> = .init()
  public var methodImplDocs: AdaptedEntityStore<MethodImpl, MethodImplDocumentation> = .init()
  public var subscriptDeclDocs: AdaptedEntityStore<SubscriptDecl, SubscriptDeclDocumentation> = .init()
  public var subscriptImplDocs: AdaptedEntityStore<SubscriptImpl, SubscriptImplDocumentation> = .init()
  public var initializerDocs: AdaptedEntityStore<InitializerDecl, InitializerDocumentation> = .init()

  public var traitDocs: AdaptedEntityStore<TraitDecl, TraitDocumentation> = .init()
  public var productTypeDocs: AdaptedEntityStore<ProductTypeDecl, ProductTypeDocumentation> = .init()

  public init() {}
}