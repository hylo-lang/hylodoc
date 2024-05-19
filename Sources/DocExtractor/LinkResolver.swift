import Foundation
import DocumentationDB
@testable import FrontEnd

public struct EntityRef {
  public let moduleName: String?
  public let identifiers: [String]
  // todo add function parameter labels
}

// todo support parameter labels
public func parseName(name: String) -> EntityRef? {
  let components = name
    .components(separatedBy: ".")
    .map({ $0.trimmingCharacters(in: .whitespaces) })
  
  if (components.isEmpty) { return nil }
  
  var moduleName: String? = nil
  let first = components[0]
  if(first.starts(with: "@")) {
    moduleName = String(first.suffix(from: first.index(after: first.startIndex)))
  }

  let identifiers = moduleName != nil ? Array(components[1...]) : components
  
  return EntityRef(moduleName: moduleName, identifiers: identifiers)
}

public func resolveReference(refString: String, in scope: AnyScopeID, exposedTo: AnyScopeID, using typeChecker: inout TypeChecker) -> Set<AnyDeclID>? {
  return parseName(name: refString).flatMap({ ref in
    return resolveReference(ref: ref, in: scope, exposedTo: exposedTo, using: &typeChecker)
  })
}


public func resolveReference(ref: EntityRef, in scope: AnyScopeID, exposedTo: AnyScopeID, using typeChecker: inout TypeChecker) -> Set<AnyDeclID>? {
  if(ref.moduleName != nil) {
    let ast = typeChecker.program.ast
    let moduleId = ast.modules.first(where: { moduleId in
      return ast[moduleId].baseName == ref.moduleName
    })
    guard moduleId != nil else { return nil }

    let moduleScope = AnyScopeID(moduleId!)
    return resolveReference(identifiers: .init(ref.identifiers), in: moduleScope, exposedTo: exposedTo, using: &typeChecker)
  }
  return resolveReference(identifiers: .init(ref.identifiers), in: scope, exposedTo: scope, using: &typeChecker)
}

public func resolveReference(identifiers: ArraySlice<String>, in scope: AnyScopeID, exposedTo: AnyScopeID, using typeChecker: inout TypeChecker) -> Set<AnyDeclID>? {
  guard let first = identifiers.first else { return nil }

  return typeChecker.lookup(unqualified: first, in: scope)
  
  // let decls = typeChecker.lookup(first, in: scope, exposedTo: exposedTo)

  // let rest = identifiers.dropFirst()

  // if (rest.isEmpty) { return decls }

  // var result = Set<AnyDeclID>()

  // for decl in decls { 
  //   guard let subRes = resolveReference(identifiers: rest, in: typeChecker.program.nodeToScope[decl]!, exposedTo: exposedTo, using: &typeChecker) else {return nil}
  //   result.formUnion(subRes)
  // }

  // return result

}

public func resolveLinkExample() {
    let productName = "myProduct"

    let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("ExampleModule")

    
    /// An instance that includes just the standard library.
    var ast = AST(ConditionalCompilationFactors())

    var diagnostics = DiagnosticSet()

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      productName, 
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    struct V: ASTWalkObserver {

      let program: ScopedProgram

      var stack: [AnyNodeID] = []

      init(_ p: ScopedProgram) {
        self.program = p
      }

      func resolveLink(_ link: String) -> AnyDeclID? {
        var linkComponents = link.components(separatedBy: ".")
        let baseIdentifier = linkComponents.removeFirst()

        let base = findBase(baseIdentifier, 0)
        if (base == nil) { return nil }
        let target = walkLink(base!, &linkComponents)
        return target;
      }

      func walkLink(_ base: AnyDeclID, _ components: inout [String]) -> AnyDeclID? {
        if (components.isEmpty) { return base }
        let currentComponent = components.removeFirst()

        if let d = ProductTypeDecl.ID(base) {
          let decl = program.ast[d]
          for m in decl.members {
            let identifier = retrieveIdentifier(m)
            if (identifier != nil && identifier == currentComponent) {
              return walkLink(m, &components)
            }
          }
        }

        return nil
      }

      func findBase(_ base: String, _ fromScope: Int) -> AnyDeclID? {
        if (fromScope >= stack.count) { return nil }

        let scope = program.nodeToScope[stack[fromScope]]
        if (scope == nil) { return nil }
        let declIDs = program.scopeToDecls[scope!]!

        for declID in declIDs {
          let identifier = retrieveIdentifier(declID)
          if (identifier != nil && identifier! == base) { return declID }
        }

        return findBase(base, fromScope + 1)
      }

      func retrieveIdentifier(_ anyDecl: AnyDeclID) -> String? {
        if let d = ProductTypeDecl.ID(anyDecl) {
          let decl = program.ast[d]
          return decl.identifier.value
        }

        if let d = FunctionDecl.ID(anyDecl) {
          let decl = program.ast[d]
          return decl.identifier?.value
        }

        return nil
      }

      func printResolution(_ link: String, _ resolution: AnyDeclID?) {
        print(" - \(link): \(resolution != nil ? "\(resolution!)" : "Target not found!")")
      }

      mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
        stack.insert(n, at: 0)

        if let id = FunctionDecl.ID(n) {
          let decl = ast[id]
          if (decl.identifier?.value == "test1") {
            print("Resolutions in test1:")

            printResolution("MyType.test2", resolveLink("MyType.test2"))
            printResolution("test2", resolveLink("test2"))
            printResolution("MyType.InnerType", resolveLink("MyType.InnerType"))
            printResolution("InnerType", resolveLink("InnerType"))
            printResolution("test3", resolveLink("test3"))

            print()
          }
        }

        if let id = FunctionDecl.ID(n) {
          let decl = ast[id]
          if (decl.identifier?.value == "test3") {
            print("Resolutions in test3:")

            printResolution("MyType.test2", resolveLink("MyType.test2"))
            printResolution("test2", resolveLink("test2"))
            printResolution("MyType.InnerType", resolveLink("MyType.InnerType"))
            printResolution("InnerType", resolveLink("InnerType"))
            printResolution("test3", resolveLink("test3"))

            print()
          }
        }

        return true
      }

      mutating func willExit(_ n: AnyNodeID, in ast: AST) {
        stack.removeFirst()
      }
    }

    print()
    let scoped = ScopedProgram(ast)
    var v = V(scoped)

    for m in ast.modules { ast.walk(m, notifying: &v) }
}

private func shouldTraceInference(_ n: AnyNodeID, _ p: TypedProgram) -> Bool {
  return true
}
