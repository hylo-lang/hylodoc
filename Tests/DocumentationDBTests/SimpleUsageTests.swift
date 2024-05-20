import XCTest

@testable import DocumentationDB
@testable import FrontEnd

final class DocumentationDBWorks: XCTestCase {
  func insertElements() {
    var db = DocumentationDatabase()

    // These are the IDs that can be used to efficiently refer to the documentation entities.
    let childFolderDocId = db.assets.folders.insert(
        .init(
            name: "ChildFolder", 
            documentation: nil,
            children: []
        )
    )

    let parentFolderDocId = db.assets.folders.insert(
        .init(
            name: "RootFolder", 
            documentation: nil,
            children: [
                AnyAssetID.folder(childFolderDocId)
            ]
        )
    )

    // Check if the data can be retrieved correctly by documentation id
    XCTAssertEqual(db.assets.folders[parentFolderDocId]?.name, "RootFolder")
    
    let childAssetIds = db.assets.folders[parentFolderDocId]!.children
    XCTAssertEqual(childAssetIds.count, 1)
    XCTAssertEqual(childAssetIds[0], AnyAssetID.folder(childFolderDocId))

    XCTAssertEqual(db.assets.folders[childFolderDocId]?.name, "ChildFolder")
  }
}
