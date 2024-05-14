import XCTest


extension DocumentationID : Comparable { 
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.raw < rhs.raw 
  }
}

@testable import DocumentationDB
@testable import FrontEnd

final class AllChildModulesTest: XCTestCase {
  func testThatItWorks() {
    var store = AdaptedEntityStore<ModuleDecl>()
   
   // These are the IDs coming from the AST.
    let rootModuleASTNodeId : ModuleDecl.ID = .init(rawValue: 0)
    let childModuleASTNodeId1 : ModuleDecl.ID = .init(rawValue: 1)
    let childModuleASTNodeId2 : ModuleDecl.ID = .init(rawValue: 2)
    let grandChildModuleASTNodeId : ModuleDecl.ID = .init(rawValue: 3)

    // These are the IDs that can be used to efficiently refer to the documentation entities.
    let childModuleDocId1 = store.insert(
        .init(
            name: "ChildModule1", 
            documentation: nil,
            children: []
        ), 
        for: childModuleASTNodeId1
    )

    let grandChildModuleDocId = store.insert(
        .init(
            name: "GrandChildModule", 
            documentation: nil,
            children: []
        ), 
        for: grandChildModuleASTNodeId
    )

    let childModuleDocId2 = store.insert(
        .init(
            name: "ChildModule2", 
            documentation: nil,
            children: [.module(grandChildModuleDocId)]
        ), 
        for: childModuleASTNodeId2
    )

    let rootModuleDocId = store.insert(
        .init(
            name: "RootModule", 
            documentation: nil,
            children: [ .module(childModuleDocId1), .module(childModuleDocId2) ]
        ),
        for: rootModuleASTNodeId
    )

    // of module id
    XCTAssertEqual(
        store.allDescendantModules(of: rootModuleDocId).sorted(),
        [rootModuleDocId, childModuleDocId1, childModuleDocId2, grandChildModuleDocId].sorted()
    )

    // of ast node id
    XCTAssertEqual(
        store.allDescendantModules(ofAstNodeId: rootModuleASTNodeId).sorted(),
        [rootModuleDocId, childModuleDocId1, childModuleDocId2, grandChildModuleDocId].sorted()
    )


    // When the starting module is not the root:
    XCTAssertEqual(
        store.allDescendantModules(of: childModuleDocId2).sorted(),
        [childModuleDocId2, grandChildModuleDocId].sorted()
    )
  }
}