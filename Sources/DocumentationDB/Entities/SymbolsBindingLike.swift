/// Documentation of a binding declaration.
///
/// A binding might technically have multiple variable declarations inside, but for now let's
/// assume that each documented binding contains exactly one declaration.
/// - See: `VarDecl.swift` vs `BindingDecl.swift`
///
/// ```hylo
/// let (name, age): (String, Int) = ("Thomas", 21)
/// ```
public struct BindingDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields
  public let invariants: [Invariant]

  public init(common: GeneralDescriptionFields, invariants: [Invariant]) {
    self.common = common
    self.invariants = invariants
  }
}

/// Documentation of the introducer of an operator
///
/// Note: This is not the same as a MethodDecl or FunctionDecl that is an operator.
/// (Those have their notation field as Some(Infix|Prefix|Postfix).)
public struct OperatorDocumentation: IdentifiedEntity {
  public let documentation: GeneralDescriptionFields

  public init(documentation: GeneralDescriptionFields) {
    self.documentation = documentation
  }
}

/// Documentation of an associated type declaration (for a trait).
public struct AssociatedTypeDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields

  public init(common: GeneralDescriptionFields) {
    self.common = common
  }
}

/// Documentation of an associated value declaration (for a trait).
public struct AssociatedValueDocumentation: IdentifiedEntity {
  public let common: GeneralDescriptionFields

  public init(common: GeneralDescriptionFields) {
    self.common = common
  }
}
