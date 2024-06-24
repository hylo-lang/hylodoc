import DocumentationDB
import Foundation
import FrontEnd

// An entity reference that refers to a declaration in the program.
//
// - Invariant: `identifiers` is never empty if `moduleName` is nil.
public struct EntityRef: Equatable {
  public let moduleName: String?
  public let identifiers: [String]
  public let labels: [String?]?  // elements are nil if their label is `_`

  public init(moduleName: String?, identifiers: [String], labels: [String?]?) {
    precondition(!identifiers.isEmpty || moduleName != nil)
    self.moduleName = moduleName
    self.identifiers = identifiers
    self.labels = labels
  }
}

/// Parses a string into a module reference and the rest of the string.
///
/// A module reference is an @ sign followed by an identifier.
func tokenizeLinkReference(_ text: String) -> (moduleName: Substring?, tokens: [Token]) {
  let text = text.trimmingCharacters(in: .whitespaces)
  if text.isEmpty { return (nil, []) }
  if text.first == "@" {
    let tokenizedText = String(text.dropFirst())
    let tokens = Array(Lexer(tokenizing: SourceFile(synthesizedText: tokenizedText)))

    guard let first = tokens.first, case .name = first.kind else { return (nil, []) }
    let moduleName = tokenizedText[..<first.site.endIndex]

    guard let second = tokens.dropFirst().first, case .dot = second.kind else {
      return (moduleName, Array(tokens.dropFirst()))
    }

    return (moduleName, Array(tokens.dropFirst(2)))
  }
  return (nil, Array(Lexer(tokenizing: SourceFile(synthesizedText: text))))
}

public enum LinkResolverError: Error, Equatable {
  case expectedAName
  case expectedEndOfTokensAfterRightParen
  case expectedARightParen
  case expectedAColon
  case expectedADotOrLeftParenOrEndOfTokens
  case unsupportedDeclKind(kind: NodeKind)
}

/// Returns the labels of a function signature.
///
/// Parameter i: the index pointing to the token after the opening parenthesis and might be out of range.
///
/// Valid inputs are: `a:b:c:)`, `a:)`, `_:)`, `a:b:_:)`, `)`
/// Elements are nil if the label is `_`.
func parseSignature(i: Int, tokens: [Token]) -> Result<[String?], LinkResolverError> {
  var labels: [String?] = []
  var i = i

  while i < tokens.count {
    if tokens[i].kind == .rParen {
      return i == tokens.count - 1
        ? .success(labels) : .failure(.expectedEndOfTokensAfterRightParen)
    }

    guard tokens[i].kind == .name || tokens[i].kind == .under else {
      return .failure(.expectedAName)
    }
    labels.append(tokens[i].kind == .name ? String(tokens[i].site.text) : nil)
    i += 1

    if i == tokens.count {
      return .failure(.expectedAColon)
    }
    guard tokens[i].kind == .colon else { return .failure(.expectedAColon) }
    i += 1
  }
  return .failure(.expectedARightParen)
}

// todo support parameter labels
/// Parses a string into an entity reference.
///
/// An entity reference is a sequence of identifiers separated by dots, optionally prefixed by a module name which needs to be prefixed by an `@` sign.
/// Example: `@MyModule.MyType.MyMethod` or `MyType.MyMethod`
public func parseName(name: String) -> Result<EntityRef, LinkResolverError> {
  let (moduleName, tokens) = tokenizeLinkReference(name)
  let moduleNameS = moduleName.map { String($0) }

  var components: [String] = []

  var i = 0
  while i < tokens.count {
    guard tokens[i].kind == .name else { return .failure(.expectedAName) }
    components.append(String(tokens[i].site.text))
    i += 1
    if i == tokens.count {
      return .success(EntityRef(moduleName: moduleNameS, identifiers: components, labels: nil))
    }

    if tokens[i].kind == .lParen {
      return parseSignature(i: i + 1, tokens: tokens).map { labels in
        return EntityRef(
          moduleName: moduleNameS,
          identifiers: components,
          labels: labels
        )
      }
    }

    guard tokens[i].kind == .dot else { return .failure(.expectedADotOrLeftParenOrEndOfTokens) }
    i += 1
  }
  guard !components.isEmpty || moduleName != nil else { return .failure(.expectedAName) }
  return .success(
    EntityRef(
      moduleName: moduleNameS,
      identifiers: components,
      labels: nil
    )
  )
}

extension TypedProgram {
  /// Resolves a reference to a set of declarations in the given scope.
  ///
  /// The function currently supports qualifying by module name, namespace, product type, trait and type alias name.
  /// (All but the last identifier in the reference must be one of those declarations.)
  ///
  /// - Returns:
  ///   - `nil` if the reference had invalid syntax
  ///   - an empty set if the reference resolved to no declarations.
  ///   - a set of declarations if the reference resolved to one or more declarations.
  public func resolveReference(_ refString: String, in scope: AnyScopeID) throws -> Set<AnyDeclID> {
    let res = parseName(name: refString).flatMap({ ref in
      return resolveReference(ref: ref, in: scope, exposedTo: scope)
    })

    switch res {
    case .success(let decls):
      return decls
    case .failure(let error):
      throw error
    }
  }

  func resolveReference(ref: EntityRef, in scope: AnyScopeID, exposedTo: AnyScopeID) ->  //
    Result<Set<AnyDeclID>, LinkResolverError>
  {

    var result: Set<AnyDeclID>

    if let moduleName = ref.moduleName {
      guard let moduleId = ast.modules.first(where: { id in ast[id].baseName == moduleName }) else {
        return .success(.init())
      }
      // Referring to the module itself
      if ref.identifiers.isEmpty {
        return .success(.init([AnyDeclID(moduleId)]))
      }

      // qualified lookup from the module's scope
      result = lookup(
        ref.identifiers.first!,
        memberOf: ^ModuleType(moduleId, ast: ast),
        exposedTo: exposedTo
      )
    } else {
      precondition(!ref.identifiers.isEmpty)

      // unqualified lookup from the current scope
      result = lookup(unqualified: ref.identifiers.first!, in: scope)
    }

    var rest = ref.identifiers.dropFirst()

    if rest.isEmpty { return .success(result) }

    while !rest.isEmpty {
      let nextIdentifier = rest.popFirst()!
      let previousResult = result
      result = []

      for declId in previousResult {
        let typeToLookIn: AnyType

        switch declId.kind {
        case ProductTypeDecl.self:
          typeToLookIn = ^ProductType(ProductTypeDecl.ID(declId)!, ast: ast)
        case TraitDecl.self:
          typeToLookIn = ^TraitType(TraitDecl.ID(declId)!, ast: ast)
        case TypeAliasDecl.self:
          // unwrap the metatype
          typeToLookIn = ((self[TypeAliasDecl.ID(declId)!].type).base as! MetatypeType).instance
        case NamespaceDecl.self:
          typeToLookIn = ^NamespaceType(NamespaceDecl.ID(declId)!, ast: ast)
        default:
          return .failure(.unsupportedDeclKind(kind: declId.kind))
        }
        result.formUnion(lookup(nextIdentifier, memberOf: typeToLookIn, exposedTo: exposedTo))
      }
    }

    if let labels = ref.labels {
      result = result.filter { declId in
        return name(of: declId)?.labels == labels
      }
    }
    return .success(result)
  }

}
