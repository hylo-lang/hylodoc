import Foundation
import HyloStandardLibrary
import TestUtils
import XCTest

@testable import DocExtractor
@testable import FrontEnd

func expectNoError<T>(
  _ body: () throws -> T, filePath: StaticString = #filePath, line: UInt = #line
) rethrows -> T {
  do {
    return try body()
  } catch {
    XCTFail("unexpected error: \(error)", file: filePath, line: line)
    throw error
  }
}
final class NameResolutionTest: XCTestCase {
  func testTokenization() {
    let a = tokenizeLinkReference("Hello.World")
    XCTAssertNil(a.moduleName)
    XCTAssertEqual(a.tokens.count, 3)
    XCTAssertEqual(a.tokens[0].kind, .name)
    XCTAssertEqual(a.tokens[1].kind, .dot)
    XCTAssertEqual(a.tokens[2].kind, .name)

    let b = tokenizeLinkReference("@Hello.World")
    XCTAssertEqual(b.moduleName, "Hello")
    XCTAssertEqual(b.tokens.count, 1)
    XCTAssertEqual(b.tokens[0].kind, .name)
    XCTAssertEqual("World", b.tokens[0].site.text)

    let c = tokenizeLinkReference("@Hello")
    XCTAssertEqual(c.moduleName, "Hello")
    XCTAssertEqual(c.tokens.count, 0)

    let d = tokenizeLinkReference("Hello")
    XCTAssertNil(d.moduleName)
    XCTAssertEqual(d.tokens.count, 1)
    XCTAssertEqual(d.tokens[0].kind, .name)

    let e = tokenizeLinkReference("")
    XCTAssertNil(e.moduleName)
    XCTAssertEqual(e.tokens.count, 0)
  }
  func testNameParsing() {
    XCTAssertEqual(
      .failure(LinkResolverError.expectedAName),
      parseName(name: "")
    )

    XCTAssertEqual(
      .success(EntityRef(moduleName: nil, identifiers: ["Hello"], labels: nil)),
      parseName(name: "Hello")
    )

    XCTAssertEqual(
      .success(EntityRef(moduleName: nil, identifiers: ["Hello", "World"], labels: nil)),
      parseName(name: "Hello.World")
    )

    XCTAssertEqual(
      .success(EntityRef(moduleName: "Hello", identifiers: [], labels: nil)),
      parseName(name: "@Hello")
    )

    XCTAssertEqual(
      .success(EntityRef(moduleName: "Hello", identifiers: ["World"], labels: nil)),
      parseName(name: "@Hello.World")
    )

    XCTAssertEqual(
      .success(EntityRef(moduleName: "Hello", identifiers: ["World", "MyType"], labels: nil)),
      parseName(name: "@Hello.World.MyType")
    )

    XCTAssertEqual(
      .success(
        EntityRef(moduleName: "Hello", identifiers: ["World", "MyType", "MyMethod"], labels: nil)),
      parseName(name: "@Hello.World.MyType.MyMethod")
    )

    XCTAssertEqual(
      .success(
        EntityRef(
          moduleName: nil,
          identifiers: ["MyMethod"],
          labels: []
        )
      ),
      parseName(name: "MyMethod()")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedAName),
      parseName(name: "@MyMethod()")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedARightParen),
      parseName(name: "MyMethod(")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedAColon),
      parseName(name: "MyMethod(a)")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedAColon),
      parseName(name: "MyMethod(a:b)")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedARightParen),
      parseName(name: "MyMethod(a:")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedAColon),
      parseName(name: "MyMethod(a")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedEndOfTokensAfterRightParen),
      parseName(name: "MyMethod(a:b:) _")
    )

    XCTAssertEqual(
      .failure(LinkResolverError.expectedAName),
      parseName(name: "MyMethod(:)")
    )

    XCTAssertEqual(
      .success(
        EntityRef(
          moduleName: nil,
          identifiers: ["MyMethod"],
          labels: ["a", "b"]
        )
      ),
      parseName(name: "MyMethod(a:b:)")
    )

    XCTAssertEqual(
      .success(
        EntityRef(
          moduleName: nil,
          identifiers: ["MyMethod"],
          labels: ["a", nil]
        )
      ),
      parseName(name: "MyMethod(a:_:)")
    )

    XCTAssertEqual(
      .success(
        EntityRef(
          moduleName: nil,
          identifiers: ["MyMethod"],
          labels: [nil, nil]
        )
      ),
      parseName(name: "MyMethod(_:_:)")
    )

    XCTAssertEqual(
      .success(
        EntityRef(
          moduleName: nil,
          identifiers: ["MyMethod"],
          labels: [nil, "a"]
        )
      ),
      parseName(name: "MyMethod(_:a:)")
    )
  }
  func testNameResolution() throws {

    var ast = try checkNoDiagnostic { d in try AST.loadStandardLibraryCore(diagnostics: &d) }

    // The module whose Hylo files were given on the command-line
    let _ = try checkNoDiagnostic { d in
      try ast.makeModule(
        "RootModule",
        sourceCode: sourceFiles(in: [
          URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(
            "RootModule")
        ]),
        builtinModuleAccess: true,
        diagnostics: &d
      )
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in return false }
      )
    }

    let vectorScope = AnyScopeID(ast.resolveProductType(by: "Vector")!)

    let isFunction = { (name: String, params: [String]) in
      { (id: AnyDeclID) -> Bool in
        guard let funcDeclId = FunctionDecl.ID(id) else { return false }
        let funcDecl = typedProgram[funcDeclId]
        return funcDecl.identifier!.value == name && funcDecl.parameters.count == params.count
          && zip(funcDecl.parameters, params).allSatisfy { (paramId, paramName) in
            ast[paramId].baseName == paramName
          }
      }
    }

    let isProductType = { (withName: String) in
      { (id: AnyDeclID) -> Bool in
        guard let typeDeclId = ProductTypeDecl.ID(id) else { return false }
        let typeDecl = typedProgram[typeDeclId]
        return typeDecl.baseName == withName
      }
    }

    let isTrait = { (withName: String) in
      { (id: AnyDeclID) -> Bool in
        guard let traitDeclId = TraitDecl.ID(id) else { return false }
        let traitDecl = typedProgram[traitDeclId]
        return traitDecl.baseName == withName
      }
    }

    let isNamespace = { (withName: String) in
      { (id: AnyDeclID) -> Bool in
        guard let namespaceDeclId = NamespaceDecl.ID(id) else { return false }
        let namespaceDecl = typedProgram[namespaceDeclId]
        return namespaceDecl.baseName == withName
      }
    }

    let isTypeAlias = { (withName: String) in
      { (id: AnyDeclID) -> Bool in
        guard let typeAliasDeclId = TypeAliasDecl.ID(id) else { return false }
        let typeAliasDecl = typedProgram[typeAliasDeclId]
        return typeAliasDecl.baseName == withName
      }
    }

    // add
    let _add = try expectNoError { try typedProgram.resolveReference("add", in: vectorScope) }
    XCTAssertTrue(_add.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_add.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_add.count, 2)

    // Vector.add
    let _vectorDotAdd = try expectNoError {
      try typedProgram.resolveReference("Vector.add", in: vectorScope)
    }
    XCTAssertTrue(_vectorDotAdd.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_vectorDotAdd.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_vectorDotAdd.count, 2)

    // Vector
    let _vector = try expectNoError { try typedProgram.resolveReference("Vector", in: vectorScope) }
    XCTAssertTrue(_vector.contains(where: isProductType("Vector")))
    XCTAssertEqual(_vector.count, 1)

    // @RootModule
    let _rootModule = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule", in: vectorScope)
    }
    XCTAssertEqual(_rootModule.count, 1)

    // nothing
    do {
      let res = try typedProgram.resolveReference("", in: vectorScope)
      XCTFail("This shouldn't have succeeded but got \(res)")
    } catch let e as LinkResolverError {
      XCTAssertEqual(e, .expectedAName)
    } catch {
      XCTFail("unexpected error")
    }

    // Not found module name

    let res = try expectNoError {
      try typedProgram.resolveReference("@OtherRandomModule", in: vectorScope)
    }
    XCTAssertEqual(res.count, 0, "Shouldn't have found anything but got \(res)")

    // @RootModule.Vector

    let _rootModuleDotVector = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Vector", in: vectorScope)
    }
    XCTAssertTrue(_rootModuleDotVector.contains(where: isProductType("Vector")))
    XCTAssertEqual(_rootModuleDotVector.count, 1)

    // @RootModule.Vector.add

    let _rootModuleDotVectorDotAdd = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Vector.add", in: vectorScope)
    }
    XCTAssertTrue(_rootModuleDotVectorDotAdd.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_rootModuleDotVectorDotAdd.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_rootModuleDotVectorDotAdd.count, 2)

    // overload resolution should work
    let _rootModuleDotVectorDotAddWithOverload1 = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Vector.add(dx:dy:)", in: vectorScope)
    }
    XCTAssertTrue(
      _rootModuleDotVectorDotAddWithOverload1.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertEqual(_rootModuleDotVectorDotAddWithOverload1.count, 1)

    let _rootModuleDotVectorDotAddWithOverload2 = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Vector.add(s:)", in: vectorScope)
    }
    XCTAssertTrue(_rootModuleDotVectorDotAddWithOverload2.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_rootModuleDotVectorDotAddWithOverload2.count, 1)

    // Inner
    let _inner = try expectNoError { try typedProgram.resolveReference("Inner", in: vectorScope) }
    XCTAssertTrue(_inner.contains(where: isProductType("Inner")))
    XCTAssertEqual(_inner.count, 1)

    // Inner.add
    let _innerDotAdd = try expectNoError {
      try typedProgram.resolveReference("Inner.add", in: vectorScope)
    }
    XCTAssertTrue(_innerDotAdd.contains(where: isFunction("add", ["dx"])))
    XCTAssertEqual(_innerDotAdd.count, 1)

    // Innerlijke (type alias)
    let _innerlijke = try expectNoError {
      try typedProgram.resolveReference("Innerlijke", in: vectorScope)
    }
    XCTAssertTrue(_innerlijke.contains(where: isTypeAlias("Innerlijke")))
    XCTAssertEqual(_innerlijke.count, 1)

    // Innerlijke.add
    let _innerlijkeDotAdd = try expectNoError {
      try typedProgram.resolveReference(
        "Innerlijke.add", in: vectorScope)
    }
    XCTAssertTrue(_innerlijkeDotAdd.contains(where: isFunction("add", ["dx"])))
    XCTAssertEqual(_innerlijkeDotAdd.count, 1)

    // @RootModule.Vector.Inner

    let _rootModuleDotVectorDotInner = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Vector.Inner", in: vectorScope)
    }
    XCTAssertTrue(_rootModuleDotVectorDotInner.contains(where: isProductType("Inner")))
    XCTAssertEqual(_rootModuleDotVectorDotInner.count, 1)

    // @RootModule.Inner shouldn't exist because it's only present in an inner scope

    let _rootModuleDotInner = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.Inner", in: vectorScope)
    }
    XCTAssertEqual(_rootModuleDotInner.count, 0)

    // // todo: myMethod.inout
    // guard
    //   let _myMethodDotInout = typedProgram.resolveReference(
    //     "myMethod.inout", in: vectorScope)
    // else { return XCTFail("parsing error") }
    // XCTAssertEqual(_myMethodDotInout.count, 1)
    // print(_myMethodDotInout)
    do {
      _ = try typedProgram.resolveReference(
        "myMethod.inoutTODO", in: vectorScope)
    } catch let error as LinkResolverError {
      XCTAssertEqual(error, LinkResolverError.unsupportedDeclKind(kind: MethodDecl.kind))
    } catch {
      XCTFail("unexpected error")
    }

    // BASE_NS
    let _baseNS = try expectNoError {
      try typedProgram.resolveReference("BASE_NS", in: vectorScope)
    }
    XCTAssertTrue(_baseNS.contains(where: isNamespace("BASE_NS")))
    XCTAssertEqual(_baseNS.count, 1)

    // @RootModule.BASE_NS
    let _rootModuleDotBaseNS = try expectNoError {
      try typedProgram.resolveReference(
        "@RootModule.BASE_NS", in: vectorScope)
    }
    XCTAssertTrue(_rootModuleDotBaseNS.contains(where: isNamespace("BASE_NS")))
    XCTAssertEqual(_rootModuleDotBaseNS.count, 1)

    // BASE_NS.INNER_NS

    let _baseNSDotInnerNS = try expectNoError {
      try typedProgram.resolveReference(
        "BASE_NS.INNER_NS", in: vectorScope)
    }
    XCTAssertTrue(_baseNSDotInnerNS.contains(where: isNamespace("INNER_NS")))
    XCTAssertEqual(_baseNSDotInnerNS.count, 1)

    // INNER_NS
    let _innerNS = try expectNoError {
      try typedProgram.resolveReference("INNER_NS", in: vectorScope)
    }
    XCTAssertEqual(_innerNS.count, 0)

    // BASE_NS.string
    let _baseNSDotString = try expectNoError {
      try typedProgram.resolveReference("BASE_NS.string", in: vectorScope)
    }
    XCTAssertTrue(_baseNSDotString.contains(where: isProductType("string")))
    XCTAssertEqual(_baseNSDotString.count, 1)

    // BASE_NS.INNER_NS.Flower
    let _baseNSDotInnerNSDotFlower = try expectNoError {
      try typedProgram.resolveReference(
        "BASE_NS.INNER_NS.Flower", in: vectorScope)
    }
    XCTAssertTrue(_baseNSDotInnerNSDotFlower.contains(where: isProductType("Flower")))
    XCTAssertEqual(_baseNSDotInnerNSDotFlower.count, 1)

    // BASE_NS.INNER_NS.string shouldn't be there because of qualified lookup
    let _baseNSDotInnerNSDotString = try expectNoError {
      try typedProgram.resolveReference(
        "BASE_NS.INNER_NS.string", in: vectorScope)
    }
    XCTAssertEqual(_baseNSDotInnerNSDotString.count, 0)

    // Flower
    let _flower = try expectNoError { try typedProgram.resolveReference("Flower", in: vectorScope) }
    XCTAssertEqual(_flower.count, 0)

    // Collapsible
    let _collapsible = try expectNoError {
      try typedProgram.resolveReference("Collapsible", in: vectorScope)
    }
    XCTAssertTrue(_collapsible.contains(where: isTrait("Collapsible")))

    // Collapsible.collapse
    let _collapsibleDotCollapse = try expectNoError {
      try typedProgram.resolveReference(
        "Collapsible.collapse", in: vectorScope)
    }
    XCTAssertTrue(_collapsibleDotCollapse.contains(where: isFunction("collapse", [])))
    XCTAssertEqual(_collapsibleDotCollapse.count, 1)

    // VarDecl inside a function should not be visible
    let outerFuncId = ast.resolveFunc(by: "varDeclInsideFunctionTest")!
    let innerResolved = try expectNoError {
      try typedProgram.resolveReference(
        "myVarInsideTheFunction", in: AnyScopeID(outerFuncId))
    }
    XCTAssertEqual(innerResolved.count, 0)

    // but outside it should
    let outerResolved = try expectNoError {
      try typedProgram.resolveReference(
        "varDeclOutsideTheFunction", in: AnyScopeID(outerFuncId))
    }
    XCTAssertEqual(outerResolved.count, 1)

    // parameters should be resolved in function scope
    let paramResolved = try expectNoError {
      try typedProgram.resolveReference(
        "parameterHere", in: AnyScopeID(outerFuncId))
    }
    XCTAssertEqual(paramResolved.count, 1)
  }

  func testManualLinkResolutionUsingHyloTypeChecker() throws {
    var ast = try checkNoDiagnostic { d in try AST.loadStandardLibraryCore(diagnostics: &d) }

    // The module whose Hylo files were given on the command-line
    let rootModuleId = try checkNoDiagnostic { d in
      try ast.makeModule(
        "RootModule",
        sourceCode: sourceFiles(in: [
          URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(
            "RootModule")
        ]),
        builtinModuleAccess: true,
        diagnostics: &d
      )
    }

    let typedProgram = try checkNoDiagnostic { d in
      try TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &d,
        tracingInferenceIf: { (_, _) in false }
      )
    }
    var typeChecker = TypeChecker.init(asContextFor: typedProgram)

    let rootModuleScope = AnyScopeID(rootModuleId)

    // Given the declaration ID of Vector
    let vectorOcc = typeChecker.lookup(unqualified: "Vector", in: rootModuleScope)
    XCTAssertEqual(1, vectorOcc.count)
    let vectorDeclId = ProductTypeDecl.ID(vectorOcc.first!)!

    // Get the scope related to MyType
    let vectorScopeId = AnyScopeID(vectorDeclId)

    // get the type of Vector
    let vectorType = ^ProductType(vectorDeclId, ast: typeChecker.program.ast)

    let addOcc = typeChecker.lookup(
      "add",
      memberOf: vectorType,
      exposedTo: vectorScopeId
    )
    XCTAssertEqual(addOcc.count, 2)

    let innerTypeOcc = typeChecker.lookup(
      "Inner",
      memberOf: vectorType,
      exposedTo: vectorScopeId
    )
    XCTAssertEqual(1, innerTypeOcc.count)

    let innerDeclId = ProductTypeDecl.ID(innerTypeOcc.first!)!

    let innerType = ProductType(innerDeclId, ast: typeChecker.program.ast)

    let innerAddOcc = typeChecker.lookup(
      "add", memberOf: AnyType(innerType), exposedTo: vectorScopeId)
    print(innerAddOcc)
    XCTAssertEqual(1, innerAddOcc.count)

  }
}
