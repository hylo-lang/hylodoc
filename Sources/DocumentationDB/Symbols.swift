/// # File-Level
///
/// This file contains the data stored about symbols in the documentation database.
/// When editing, look up the specification for the corresponding syntactic element that
/// you want to add: [https://github.com/hylo-lang/specification/blob/main/spec.md](Hylo Language Specification)
/// Note: the specification may be out of date in some cases, so ask Dimi if you are in doubt.
//
// We have already collected many types of symbols to document, see

// todo extend this to support arrays, and types with generic parameters, make it a recursive type
// todo support structural types such as tuples
// One might want to represent something like this: `Union<A, B>`
// -> here A and B are generic parameters, and Equatable and Hashable are constraints (traits) on them
//
// For now, this works for Int, String, and for these very simple types.
public struct TypeReference {
  /// The name of the type reference used in the declaration. (e.g. `Int` in `let x: Int`)
  public let name: String

  /// The symbol that this type reference refers to, if it exists in the database.
  public let symbol: SymbolID?
}

/// A range of characters in a source file.
///
/// note: lookup is nontrivial (O(n)) because of unicode
public typealias SourceRange = Range<String.Index>

/// Common fields that all symbols have.
public struct SymbolCommon {
  /// The name of the symbol.
  public let name: String

  /// The source asset that this symbol is defined in.
  public let sourceAsset: SourceFileAsset.ID

  /// The range of characters in the source file where this symbol is defined.
  public let sourceRange: SourceRange
}

public enum Mutability {
  case mutable
  case immutable
}

public enum SymbolVisibility {
  case Private
  case Public
}

public enum PassingConvention {
  case `inout`
  case `let`
  case `sink`
  case `set`
}

public enum MethodReceiverConvention {
  case `inout`
  case `let`
  case `sink`
}

public enum ParameterName {
  case unnamed(internalName: String)
  case namedSame(as: String)
  case namedDifferent(internalName: String, externalName: String)

  public var externalName: String? {
    switch self {
    case .unnamed:
      return nil
    case .namedSame(as: let name):
      return name
    case .namedDifferent(_, let name):
      return name
    }
  }
}

public struct Parameter {
  public let name: ParameterName
  public let type: TypeReference
  public let passingConvention: PassingConvention
  public let defaultValue: String?
}

/// A function declaration that is outside of a type or trait declaration.
public struct FunctionDeclaration {
    public typealias ID = CustomID<FunctionDeclaration>

    public let common: SymbolCommon
    public let parameters: [Parameter]
    public let returnType: TypeReference
    public let visibility: SymbolVisibility
    // todo add support for list of generic parameters (note: they can be both types and values)
    // see: https://github.com/hylo-lang/specification/blob/main/spec.md#generic-clauses
}

/// A let or var binding declaration
///
/// Note: In the source code, one might declare a binding pattern:
/// ```hylo
/// let (name, age): (String, Int) = ("Thomas", 21)
/// ```
/// In this case, it should be represented as multiple separate binding declarations, and any
/// potential documentation above should be just copied for now. Later, we might want to
/// support a more complex representation and a custom documentation for binding patterns.
public struct BindingDeclaration {
  public typealias ID = CustomID<BindingDeclaration>

  public let common: SymbolCommon
  public let type: TypeReference
  public let visibility: SymbolVisibility
  public let mutability: Mutability
  // todo might need to be something more complex but for now it's OK
  public let defaultValue: String?
}

/// A method declaration that is inside a type or trait declaration.
// todo: revise, design the data type better for representing static / instance methods (static methods don't have receiver convention)
// public struct MethodDeclaration {
//     public typealias ID = CustomID<MethodDeclaration>

//     public let common: SymbolCommon
//     public let receiverConvention: MethodReceiverConvention
//     public let parameters: [Parameter]
//     public let returnType: TypeReference
//     public let isStatic: Bool
//     public let visibility: SymbolVisibility
// }


public enum SymbolID {
  case function(FunctionDeclaration.ID)
  case binding(BindingDeclaration.ID)
  // todo: add more cases for other kinds of symbols
}


public struct SymbolDatabase {
  var functions: EntityStore<FunctionDeclaration> = .init()
  var bindings: EntityStore<BindingDeclaration> = .init()
  // todo: add more cases for other kinds of symbols
}
