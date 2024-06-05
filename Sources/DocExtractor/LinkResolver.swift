import DocumentationDB
import Foundation

@testable import FrontEnd

public struct EntityRef {
  public let moduleName: String?
  public let identifiers: [String]
  // todo add function parameter labels
}

// todo support parameter labels
/// Parses a string into an entity reference.
///
/// An entity reference is a sequence of identifiers separated by dots, optionally prefixed by a module name which needs to be prefixed by an `@` sign.
/// Example: `@MyModule.MyType.MyMethod` or `MyType.MyMethod`
public func parseName(name: String) -> EntityRef? {
  let components =
    name
    .components(separatedBy: ".")
    .map({ $0.trimmingCharacters(in: .whitespaces) })

  if components.isEmpty { return nil }

  var moduleName: String? = nil
  let first = components[0]
  if first.starts(with: "@") {
    moduleName = String(first.suffix(from: first.index(after: first.startIndex)))
  }

  let identifiers = moduleName != nil ? Array(components[1...]) : components

  return EntityRef(moduleName: moduleName, identifiers: identifiers)
}

/// Resolves a reference to a set of declarations in the given scope.
/// 
/// The function currently supports qualifying by module name, namespace, product type, trait and type alias name.
/// (All but the last identifier in the reference must be one of those declarations.)
/// 
/// - Returns:
///   - `nil` if the reference had invalid syntax
///   - an empty set if the reference resolved to no declarations.
///   - a set of declarations if the reference resolved to one or more declarations.
public func resolveReference(
  _ refString: String, in scope: AnyScopeID, using typeChecker: inout TypeChecker
) -> Set<AnyDeclID>? {
  return parseName(name: refString).flatMap({ ref in
    return resolveReference(ref: ref, in: scope, exposedTo: scope, using: &typeChecker)
  })
}

public func resolveReference(
  ref: EntityRef, in scope: AnyScopeID, exposedTo: AnyScopeID, using typeChecker: inout TypeChecker
) -> Set<AnyDeclID>? {

  var result: Set<AnyDeclID>

  if let moduleName = ref.moduleName {
    let ast = typeChecker.program.ast
    guard let moduleId = ast.modules.first(where: { id in ast[id].baseName == moduleName }) else {
      return nil
    }
    // qualified lookup from the module's scope
    result = typeChecker.lookup(
      ref.identifiers.first!, memberOf: ^ModuleType(moduleId, ast: ast), exposedTo: exposedTo)
  } else {
    // unqualified lookup from the current scope
    result = typeChecker.lookup(unqualified: ref.identifiers.first!, in: scope)
  }

  var rest = ref.identifiers.dropFirst()

  if rest.isEmpty { return result }

  while !rest.isEmpty {
    let nextIdentifier = rest.popFirst()!
    let previousResult = result
    result = []

    for declId in previousResult {
      let typeToLookIn =
        switch declId.kind {
        case ProductTypeDecl.self:
          ^ProductType(ProductTypeDecl.ID(declId)!, ast: typeChecker.program.ast)
        case TraitDecl.self:
          ^TraitType(TraitDecl.ID(declId)!, ast: typeChecker.program.ast)
        case TypeAliasDecl.self:
          // unwrap the metatype
          ((typeChecker.program[TypeAliasDecl.ID(declId)!].type).base as! MetatypeType).instance
        case NamespaceDecl.self:
          ^NamespaceType(NamespaceDecl.ID(declId)!, ast: typeChecker.program.ast)
        default:
          fatalError("unsupported decl kind: \(declId.kind)")
        }
      result.formUnion(
        typeChecker.lookup(nextIdentifier, memberOf: typeToLookIn, exposedTo: exposedTo))
    }
  }

  return result
}
