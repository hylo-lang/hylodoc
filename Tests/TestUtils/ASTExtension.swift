import FrontEnd

extension AST {

  public func resolveProductType(by name: String) -> ProductTypeDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: ProductTypeDecl.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = ProductTypeDecl.ID(id), ast[d].baseName == targetName {
          result = d
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveTypeAlias(by name: String) -> TypeAliasDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: TypeAliasDecl.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = TypeAliasDecl.ID(id), ast[d].baseName == targetName {
          result = d
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveAssociatedType(by name: String) -> AssociatedTypeDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: AssociatedTypeDecl.ID?
      var members: [AnyDeclID] = []
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let e = TraitDecl.ID(id) {
          members = ast[e].members
          for member in members {
            if let d = AssociatedTypeDecl.ID(member), ast[d].baseName == targetName {
              result = d
              return false
            }
          }
        }

        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveAssociatedValue(by name: String) -> AssociatedValueDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: AssociatedValueDecl.ID?
      var members: [AnyDeclID] = []
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let e = TraitDecl.ID(id) {
          members = ast[e].members
          for member in members {
            if let d = AssociatedValueDecl.ID(member), ast[d].baseName == targetName {
              result = d
              return false
            }
          }
        }

        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveBinding() -> [BindingDecl.ID]? {
    struct ASTWalker: ASTWalkObserver {
      var result: [BindingDecl.ID]?

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = BindingDecl.ID(id) {
          if result == nil {
            result = [BindingDecl.ID]()
          }
          result?.append(d)
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveOperator() -> [OperatorDecl.ID]? {
    struct ASTWalker: ASTWalkObserver {
      var result: [OperatorDecl.ID]?

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = OperatorDecl.ID(id) {
          if result == nil {
            result = [OperatorDecl.ID]()
          }
          result?.append(d)
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveFunc(by name: String) -> FunctionDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: FunctionDecl.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = FunctionDecl.ID(id), ast[d].identifier?.value == targetName {
          result = d
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveMethodDecl(by name: String) -> MethodDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: MethodDecl.ID?
      var members: [AnyDeclID] = []
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let e = ProductTypeDecl.ID(id) {
          members = ast[e].members
          for member in members {
            if let d = MethodDecl.ID(member), ast[d].identifier.value == targetName {
              result = d
              return false
            }
          }
        }

        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveMethodImpl(by name: String) -> [MethodImpl.ID]? {
    struct ASTWalker: ASTWalkObserver {
      var result: [MethodImpl.ID]?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = MethodDecl.ID(id), ast[d].identifier.value == targetName {
          result = ast[MethodDecl.ID(d)]?.impls
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveSubscriptDecl(by name: String) -> SubscriptDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: SubscriptDecl.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = SubscriptDecl.ID(id), ast[d].identifier?.value == targetName {
          result = d
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveSubscriptImpl(by name: String) -> [SubscriptImpl.ID]? {
    struct ASTWalker: ASTWalkObserver {
      var result: [SubscriptImpl.ID]?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = SubscriptDecl.ID(id), ast[d].identifier?.value == targetName {
          result = ast[SubscriptDecl.ID(d)]?.impls
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveInit(by name: String) -> InitializerDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: InitializerDecl.ID?
      var members: [AnyDeclID] = []
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let e = ProductTypeDecl.ID(id), ast[e].baseName == targetName {
          members = ast[e].members
          for member in members {
            if let d = InitializerDecl.ID(member) {
              result = d
              return false
            }
          }
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public func resolveTrait(by name: String) -> TraitDecl.ID? {
    struct ASTWalker: ASTWalkObserver {
      var result: TraitDecl.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = TraitDecl.ID(id), ast[d].baseName == targetName {
          result = d
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  /// - Parameter name: file name without extension
  public func resolveTranslationUnit(by name: String) -> TranslationUnit.ID? {
    precondition(name.hasSuffix(".hylo"), "Name should be passed with extension.")

    struct ASTWalker: ASTWalkObserver {
      var result: TranslationUnit.ID?
      let targetName: String

      mutating func willEnter(_ id: AnyNodeID, in ast: AST) -> Bool {
        if let d = TranslationUnit.ID(id) {
          if ast[d].site.file.baseName == targetName {
            result = d
          }
          // print("Found \(ast[d].site.file.baseName) with content: \(ast[d].site.text)")
          return false
        }
        return true
      }
    }

    var walker = ASTWalker(result: nil, targetName: name)
    for m in modules {
      walk(m, notifying: &walker)
    }
    return walker.result
  }

  public init(fromSingleSourceFile: SourceFile, diagnostics: inout DiagnosticSet) {
    self.init(ConditionalCompilationFactors())
    let sourceFile = fromSingleSourceFile
    let _ = try! makeModule(
      "RootModule",
      sourceCode: [sourceFile],
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )
  }

  public mutating func addModule(
    fromSingleSourceFile: SourceFile, diagnostics: inout DiagnosticSet,
    moduleName: String = "RootModule"
  ) throws -> ModuleDecl.ID {
    let sourceFile = fromSingleSourceFile
    return try makeModule(
      moduleName,
      sourceCode: [sourceFile],
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )
  }
}
