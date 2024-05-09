import XCTest

@testable import DocumentationDB
@testable import FrontEnd

final class DocumentationDBWorks: XCTestCase {
  func insertElements() {
    var db = DocumentationDatabase()

    // These are the IDs coming from the AST.
    let rootModuleASTNodeId : ModuleDecl.ID = .init(rawValue: 0)
    let childModuleASTNodeId : ModuleDecl.ID = .init(rawValue: 1)

    // These are the IDs that can be used to efficiently refer to the documentation entities.
    let childModuleDocId = db.assetStore.modules.insert(
        .init(
            name: "ChildModule", 
            documentation: nil,
            children: []
        ), 
        for: childModuleASTNodeId
    )

    let parentModuleDocId = db.assetStore.modules.insert(
        .init(
            name: "RootModule", 
            documentation: nil,
            children: [
                AnyAssetID.module(childModuleDocId)
            ]
        ),
        for: rootModuleASTNodeId
    )

    // Check if the data can be retrieved correctly by documentation id
    XCTAssertEqual(db.assetStore.modules[documentationId: parentModuleDocId]?.name, "RootModule")
    
    let childAssetIds = db.assetStore.modules[documentationId: parentModuleDocId]!.children
    XCTAssertEqual(childAssetIds.count, 1)
    XCTAssertEqual(childAssetIds[0], AnyAssetID.module(childModuleDocId))

    XCTAssertEqual(db.assetStore.modules[documentationId: childModuleDocId]?.name, "ChildModule")


    // Check if the data can be retrieved correctly by AST id
    XCTAssertEqual(db.assetStore.modules[astNodeId: rootModuleASTNodeId]?.name, "RootModule")
    XCTAssertEqual(db.assetStore.modules[astNodeId: childModuleASTNodeId]?.name, "ChildModule")
  }
}
