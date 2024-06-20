/// Documentation of product types
public struct ProductTypeDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
  public let invariants: [Invariant]
  public let genericParameters: GenericParameterDocumentations

  public init(
    common: GeneralDescriptionFields, 
    invariants: [Invariant],
    genericParameters: GenericParameterDocumentations
    ) {
      self.common = common
      self.invariants = invariants
      self.genericParameters = genericParameters
    }
}

/// Documentation of a trait
public struct TraitDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
  public let invariants: [Invariant]

  public init(common: GeneralDescriptionFields, invariants: [Invariant]) {
    self.common = common
    self.invariants = invariants
  }
}
