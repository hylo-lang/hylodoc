import XCTest

@testable import DocExtractor
@testable import FrontEnd
@testable import StandardLibraryCore
@testable import Foundation

func loadStandardLibrary(diagnostics: inout DiagnosticSet) -> AST {
  let url = Bundle.module.url(forResource: "StandardLibraryCoreResource", withExtension: nil)!

  /// An instance that includes just the standard library.
  var ast = AST(ConditionalCompilationFactors(freestanding: true))

  // Load standard library core
  ast.coreLibrary = try! ast.makeModule(
    "Hylo",
    sourceCode: sourceFiles(in: [url]),
    builtinModuleAccess: true,
    diagnostics: &diagnostics
  )
  ast.coreTraits = .init(ast)
  return ast
}

final class LinkResolutionTest: XCTestCase {
  func testLinkResolution() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibrary(diagnostics: &diagnostics)

    // The module whose Hylo files were given on the command-line
    let rootModuleId = try! ast.makeModule(
      "RootModule",
      sourceCode: sourceFiles(in: [URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("RootModule")]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &diagnostics,
        tracingInferenceIf: {(_, _) in return false})

    var typeChecker = TypeChecker.init(asContextFor: typedProgram)

    let rootModuleScope = AnyScopeID(rootModuleId)
    let typeSet = typeChecker.lookup("MyType", in: rootModuleScope, exposedTo: rootModuleScope)
    XCTAssertEqual(typeSet.count, 1)
    
    let myTypeId = ProductTypeDecl.ID(Array(typeSet)[0].base)!
    let myTypeScope = AnyScopeID(myTypeId)
    let addFunIds = typeChecker.lookup("add", in: myTypeScope, exposedTo: rootModuleScope)
    XCTAssertNotEqual(addFunIds.count, 0)

    print("\n\n")

    // These should all output the same result:
    print("add:                    ", resolveReference(refString: "add", in: myTypeScope, exposedTo: rootModuleScope, using: &typeChecker) ?? "invalid")
    print("MyType.add:             ", resolveReference(refString: "MyType.add", in: myTypeScope, exposedTo: rootModuleScope, using: &typeChecker) ?? "invalid")
    print("@RootModule.MyType:     ", resolveReference(refString: "@RootModule.MyType", in: myTypeScope, exposedTo: rootModuleScope, using: &typeChecker) ?? "invalid")
    print("@RootModule.MyType.add: ", resolveReference(refString: "@RootModule.MyType.add", in: myTypeScope, exposedTo: rootModuleScope, using: &typeChecker) ?? "invalid")

    print("\n\n")
    // print(typeChecker.lookup("myVar", in: AnyScopeID(rootModuleId), exposedTo: AnyScopeID(rootModuleId)))
    // print(typeChecker.lookup(unqualified: "myVar", in: AnyScopeID(rootModuleId)))


    // let n0 = Array.init(typeChecker.lookup("N0", in: AnyScopeID(rootModuleId), exposedTo: AnyScopeID(rootModuleId)))
    // if let n0Id = NamespaceDecl.ID(n0[0].base) {
    //   print("found n0: ")
    //   print(n0Id)

    //   let n1 = typeChecker.lookup("N1", in: AnyScopeID(n0Id), exposedTo: AnyScopeID(rootModuleId))
    //   print("found n1: ")
    //   print(n1)
      
    //   let n1Id = NamespaceDecl.ID(Array(n1)[0].base)!
    //   let function = typeChecker.lookup("myfunc", in: AnyScopeID(n1Id), exposedTo: AnyScopeID(rootModuleId))
    //   print("found myfunc(para:): ")
    //   print(function)
    // }

    // print("heloo")
    // print(ast.modules.map({ module in ast[module].baseName}))
  }

  func testLinkResolution2() {
    var diagnostics = DiagnosticSet()

    var ast = loadStandardLibrary(diagnostics: &diagnostics)

    // The module whose Hylo files were given on the command-line
    let rootModuleId = try! ast.makeModule(
      "RootModule",
      sourceCode: sourceFiles(in: [URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("RootModule")]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
        annotating: ScopedProgram(ast), inParallel: false,
        reportingDiagnosticsTo: &diagnostics,
        tracingInferenceIf: {(_, _) in return false})

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

    let innerAddOcc = typeChecker.lookup("add", memberOf: AnyType(innerType), exposedTo: vectorScopeId)
    print(innerAddOcc)
    XCTAssertEqual(1, innerAddOcc.count)

  }
}