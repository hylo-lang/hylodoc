import DocExtractor
import DocumentationDB
import FrontEnd
import HyloStandardLibrary
import TestUtils
import XCTest

func assetNameIs(_ name: String, _ assets: AssetStore) -> ((AnyAssetID) -> Bool) {
  { assets[$0]?.location.lastPathComponent == name }
}

final class ScanAssetsTests: XCTestCase {
  func testAssetCollection() throws {
    // GIVEN two loaded modules, ModuleA and ModuleB

    var ast = try checkNoDiagnostic { d in try AST.loadStandardLibraryCore(diagnostics: &d) }

    let baseUrl = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let moduleAPath = baseUrl.appendingPathComponent("ModuleA")
    let moduleBPath = baseUrl.appendingPathComponent("ModuleB")

    let moduleAId = try checkNoDiagnostic { d in
      try ast.makeModule(
        "ModuleA", sourceCode: sourceFiles(in: [moduleAPath]), builtinModuleAccess: true,
        diagnostics: &d
      )
    }

    let moduleBId = try checkNoDiagnostic { d in
      try ast.makeModule(
        "ModuleB", sourceCode: sourceFiles(in: [moduleBPath]), builtinModuleAccess: true,
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

    // WHEN trying to extract documentation

    let result = extractDocumentation(
      typedProgram: typedProgram,
      for: [
        .init(name: "ModuleA", rootFolderPath: moduleAPath, astId: moduleAId),
        .init(name: "ModuleB", rootFolderPath: moduleBPath, astId: moduleBId),
      ])

    // THEN the documentation should be extracted successfully
    switch result {
    case .failure(let error):
      XCTFail("Failed to extract documentation: \(error)")
    default:
      break
    }

    let db = try! result.get()

    // THEN the database should contain the two modules
    guard let moduleA = db.modules[moduleAId] else {
      return XCTFail("ModuleA not found")
    }
    guard let moduleB = db.modules[moduleBId] else {
      return XCTFail("ModuleB not found")
    }

    XCTAssertEqual(moduleA.name, "ModuleA")
    XCTAssertEqual(moduleA.astId, moduleAId)
    XCTAssertEqual(moduleA.rootFolderPath, moduleAPath)

    XCTAssertEqual(moduleB.name, "ModuleB")
    XCTAssertEqual(moduleB.astId, moduleBId)
    XCTAssertEqual(moduleB.rootFolderPath, moduleBPath)

    // THEN the database should contain the root folder of the two modules
    guard let moduleARootFolder = db.assets[moduleA.rootFolder] else {
      return XCTFail("ModuleA root folder not found")
    }

    guard let moduleBRootFolder = db.assets[moduleB.rootFolder] else {
      return XCTFail("ModuleB root folder not found")
    }

    XCTAssertEqual(moduleARootFolder.location, moduleAPath)
    XCTAssertEqual(
      moduleARootFolder.documentation, nil, "ModuleA root folder should not have documentation")
    XCTAssertEqual(moduleARootFolder.children.count, 1)

    XCTAssertEqual(moduleBRootFolder.location, moduleBPath)
    XCTAssertNotEqual(
      moduleBRootFolder.documentation, nil, "ModuleB root folder should have documentation")
    XCTAssertEqual(moduleBRootFolder.children.count, 5)

    // Check child assets
    // ModuleA/c.hylo
    guard
      let cDotHyloAnyAssetId = moduleARootFolder.children.first(
        where: assetNameIs("c.hylo", db.assets))
    else {
      return XCTFail("ModuleA root folder should contain c.hylo")
    }
    guard case .sourceFile(_) = cDotHyloAnyAssetId else {
      return XCTFail("ModuleA root folder should contain c.hylo as a source file")
    }

    // ModuleB/index.hylodoc
    guard
      let indexDotHylodocAnyAssetId = moduleBRootFolder.children.first(
        where: assetNameIs("index.hylodoc", db.assets))
    else {
      return XCTFail("ModuleB root folder should contain index.hylodoc")
    }
    guard case .article(_) = indexDotHylodocAnyAssetId else {
      return XCTFail("ModuleB root folder should contain index.hylodoc as an article")
    }

    // ModuleB/Article Without Title.hylodoc
    guard
      let articleWithoutTitleDotHylodocAnyAssetId = moduleBRootFolder.children.first(
        where: assetNameIs("Article Without Title.hylodoc", db.assets))
    else {
      return XCTFail("ModuleB root folder should contain Article Without Title.hylodoc")
    }
    guard case .article(let articleId) = articleWithoutTitleDotHylodocAnyAssetId else {
      return XCTFail(
        "ModuleB root folder should contain Article Without Title.hylodoc as an article")
    }
    XCTAssertEqual(db.assets[articleId]!.title, nil)

    // ModuleB/a.hylo
    guard
      let aDotHyloAnyAssetId = moduleBRootFolder.children.first(
        where: assetNameIs("a.hylo", db.assets))
    else {
      return XCTFail("ModuleB root folder should contain a.hylo")
    }
    guard case .sourceFile(_) = aDotHyloAnyAssetId else {
      return XCTFail("ModuleB root folder should contain a.hylo as a source file")
    }

    // ModuleB/other file.txt
    guard
      let otherFileTxtAnyAssetId = moduleBRootFolder.children.first(
        where: assetNameIs("other file.txt", db.assets))
    else {
      return XCTFail("ModuleB root folder should contain other file.txt")
    }
    guard case .otherFile(_) = otherFileTxtAnyAssetId else {
      return XCTFail("ModuleB root folder should contain 'other file.txt' as an other file asset")
    }

    // ModuleB/Subfolder
    guard
      let subfolderAnyAssetId = moduleBRootFolder.children.first(
        where: assetNameIs("Subfolder", db.assets))
    else {
      return XCTFail("ModuleB root folder should contain Subfolder")
    }
    guard case .folder(let subfolderId) = subfolderAnyAssetId else {
      return XCTFail("ModuleB root folder should contain Subfolder as a folder")
    }
    let subfolder = db.assets[subfolderId]!
    guard let subfolderDoc = subfolder.documentation else {
      return XCTFail("Subfolder should have documentation")
    }
    XCTAssertEqual(db.assets[subfolderDoc]!.title, "Title of Subfolder's Article")
    XCTAssertEqual(subfolder.children.count, 2)

    // ModuleB/Subfolder/child.hylo
    guard
      let childDotHyloAnyAssetId = subfolder.children.first(
        where: assetNameIs("child.hylo", db.assets))
    else {
      return XCTFail("Subfolder should contain child.hylo")
    }
    guard case .sourceFile(_) = childDotHyloAnyAssetId else {
      return XCTFail("Subfolder should contain child.hylo as a source file")
    }

    // ModuleB/Subfolder/index.hylodoc
    guard
      let subfolderIndexDotHylodocAnyAssetId = subfolder.children.first(
        where: assetNameIs("index.hylodoc", db.assets))
    else {
      return XCTFail("Subfolder should contain index.hylodoc")
    }
    guard case .article(let subfolderIndexArticleId) = subfolderIndexDotHylodocAnyAssetId else {
      return XCTFail("Subfolder should contain index.hylodoc as an article")
    }
    XCTAssertEqual(db.assets[subfolderIndexArticleId], db.assets[subfolder.documentation!])
  }
}
