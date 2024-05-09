
/// Documentation of product types
public struct ProductTypeDocumentation: IdentifiedEntity {
  public let generalDescription: GeneralDescriptionFields
  public let invariants: [Invariant]
}

/// Documentation of a trait
public struct TraitDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
  public let invariants: [Invariant]
}