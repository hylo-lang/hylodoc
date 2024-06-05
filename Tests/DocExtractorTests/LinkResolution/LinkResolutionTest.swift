import StandardLibraryCore
import XCTest

@testable import DocExtractor
@testable import Foundation
@testable import FrontEnd

final class NameResolutionTest: XCTestCase {
  func testNameResolution() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "RootModule",
      sourceCode: sourceFiles(in: [
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(
          "RootModule")
      ]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in return false })

    var typeChecker = TypeChecker.init(asContextFor: typedProgram)

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
    guard let _add = resolveReference("add", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_add.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_add.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_add.count, 2)

    // Vector.add
    guard
      let _vectorDotAdd = resolveReference(
        "Vector.add", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_vectorDotAdd.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_vectorDotAdd.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_vectorDotAdd.count, 2)

    // Vector
    guard let _vector = resolveReference("Vector", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_vector.contains(where: isProductType("Vector")))
    XCTAssertEqual(_vector.count, 1)

    // @RootModule.Vector
    guard
      let _rootModuleDotVector = resolveReference(
        "@RootModule.Vector", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_rootModuleDotVector.contains(where: isProductType("Vector")))
    XCTAssertEqual(_rootModuleDotVector.count, 1)

    // @RootModule.Vector.add
    guard
      let _rootModuleDotVectorDotAdd = resolveReference(
        "@RootModule.Vector.add", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_rootModuleDotVectorDotAdd.contains(where: isFunction("add", ["dx", "dy"])))
    XCTAssertTrue(_rootModuleDotVectorDotAdd.contains(where: isFunction("add", ["s"])))
    XCTAssertEqual(_rootModuleDotVectorDotAdd.count, 2)

    // Inner
    guard let _inner = resolveReference("Inner", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_inner.contains(where: isProductType("Inner")))
    XCTAssertEqual(_inner.count, 1)

    // Inner.add
    guard let _innerDotAdd = resolveReference("Inner.add", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_innerDotAdd.contains(where: isFunction("add", ["dx"])))
    XCTAssertEqual(_innerDotAdd.count, 1)

    // Innerlijke (type alias)
    guard let _innerlijke = resolveReference("Innerlijke", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_innerlijke.contains(where: isTypeAlias("Innerlijke")))
    XCTAssertEqual(_innerlijke.count, 1)

    // Innerlijke.add
    guard
      let _innerlijkeDotAdd = resolveReference(
        "Innerlijke.add", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_innerlijkeDotAdd.contains(where: isFunction("add", ["dx"])))
    XCTAssertEqual(_innerlijkeDotAdd.count, 1)

    // @RootModule.Vector.Inner
    guard
      let _rootModuleDotVectorDotInner = resolveReference(
        "@RootModule.Vector.Inner", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_rootModuleDotVectorDotInner.contains(where: isProductType("Inner")))
    XCTAssertEqual(_rootModuleDotVectorDotInner.count, 1)

    // @RootModule.Inner shouldn't exist because it's only present in an inner scope
    guard
      let _rootModuleDotInner = resolveReference(
        "@RootModule.Inner", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertEqual(_rootModuleDotInner.count, 0)

    // // todo: myMethod.inout
    // guard
    //   let _myMethodDotInout = resolveReference(
    //     "myMethod.inout", in: vectorScope, using: &typeChecker)
    // else { return XCTFail("parsing error") }
    // XCTAssertEqual(_myMethodDotInout.count, 1)
    // print(_myMethodDotInout)

    // BASE_NS
    guard let _baseNS = resolveReference("BASE_NS", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_baseNS.contains(where: isNamespace("BASE_NS")))
    XCTAssertEqual(_baseNS.count, 1)

    // @RootModule.BASE_NS
    guard
      let _rootModuleDotBaseNS = resolveReference(
        "@RootModule.BASE_NS", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_rootModuleDotBaseNS.contains(where: isNamespace("BASE_NS")))
    XCTAssertEqual(_rootModuleDotBaseNS.count, 1)

    // BASE_NS.INNER_NS
    guard
      let _baseNSDotInnerNS = resolveReference(
        "BASE_NS.INNER_NS", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_baseNSDotInnerNS.contains(where: isNamespace("INNER_NS")))
    XCTAssertEqual(_baseNSDotInnerNS.count, 1)

    // INNER_NS
    guard let _innerNS = resolveReference("INNER_NS", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertEqual(_innerNS.count, 0)

    // BASE_NS.string
    guard
      let _baseNSDotString = resolveReference(
        "BASE_NS.string", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_baseNSDotString.contains(where: isProductType("string")))
    XCTAssertEqual(_baseNSDotString.count, 1)

    // BASE_NS.INNER_NS.Flower
    guard
      let _baseNSDotInnerNSDotFlower = resolveReference(
        "BASE_NS.INNER_NS.Flower", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_baseNSDotInnerNSDotFlower.contains(where: isProductType("Flower")))
    XCTAssertEqual(_baseNSDotInnerNSDotFlower.count, 1)

    // BASE_NS.INNER_NS.string shouldn't be there because of qualified lookup
    guard
      let _baseNSDotInnerNSDotString = resolveReference(
        "BASE_NS.INNER_NS.string", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertEqual(_baseNSDotInnerNSDotString.count, 0)

    // Flower
    guard let _flower = resolveReference("Flower", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertEqual(_flower.count, 0)

    // Collapsible
    guard let _collapsible = resolveReference("Collapsible", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_collapsible.contains(where: isTrait("Collapsible")))

    // Collapsible.collapse
    guard
      let _collapsibleDotCollapse = resolveReference(
        "Collapsible.collapse", in: vectorScope, using: &typeChecker)
    else { return XCTFail("parsing error") }
    XCTAssertTrue(_collapsibleDotCollapse.contains(where: isFunction("collapse", [])))
    XCTAssertEqual(_collapsibleDotCollapse.count, 1)
  }

  func testManualLinkResolutionUsingHyloTypeChecker() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // The module whose Hylo files were given on the command-line
    let rootModuleId = try! ast.makeModule(
      "RootModule",
      sourceCode: sourceFiles(in: [
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(
          "RootModule")
      ]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _) in return false })

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
