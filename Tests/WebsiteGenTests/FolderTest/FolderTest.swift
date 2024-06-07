import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class FolderTest: XCTestCase {
  func testFolderPageGenerationNoDetailsNoChildren() {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _: TypedProgram) in false })

    var db: DocumentationDatabase = .init()

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: nil,
        children: []
      ))


    var ctx = GenerationContext(
      documentation: db,
      stencil: createDefaultStencilEnvironment(),
      typedProgram: typedProgram,
      urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
    )

    ctx.urlResolver.resolve(
      target: .asset(.folder(folder1Id)),
      filePath: RelativePath(pathString: "root/Folder1/index.html"), parent: nil)

    var res: String = ""
    do {
      res = try renderFolderPage(ctx: ctx, of: folder1Id)
    } catch {
      XCTFail("Should not throw")
    }

    XCTAssertTrue(res.contains("<title>Folder1</title>"), res)
    XCTAssertTrue(res.contains("<h1>Folder1</h1>"), res)

    XCTAssertFalse(res.contains("<h2>Details</h2>"), res)
  }

  func testFolderPageGenerationWithDetailsNoChildren() {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _: TypedProgram) in false })

    var db: DocumentationDatabase = .init()

    // Populate the database with some folder information manually:
    let documentationArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/index.hylodoc")!,
        title: "Documentation for Folder1",
        content: .document([.paragraph(Text("lorem ipsum"))])
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,  // <- important connection
        children: []
      ))

    var ctx = GenerationContext(
      documentation: db,
      stencil: createDefaultStencilEnvironment(),
      typedProgram: typedProgram,
      urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
    )

    ctx.urlResolver.resolve(
      target: .asset(.folder(folder1Id)),
      filePath: RelativePath(pathString: "root/Folder1/index.html"), parent: nil)

    let res = try! renderFolderPage(ctx: ctx, of: folder1Id)
    
    let _ = res

    // XCTAssertTrue(res.contains("<title>Documentation for Folder1</title>"), res)
    // XCTAssertTrue(res.contains("<h1>Documentation for Folder1</h1>"), res)
    // XCTAssertTrue(res.contains("<h2>Details</h2>"), res)
    // XCTAssertTrue(res.contains("<p>lorem ipsum</p>"), res)

    // XCTAssertFalse(res.contains("<a href="), res)
  }

  func testFolderPageGenerationWithDetailsWithChildren() {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    // We don't really read anything from here right now, we will the documentation database manually
    let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .appendingPathComponent("TestHyloModule")

    // The module whose Hylo files were given on the command-line
    let _ = try! ast.makeModule(
      "TestHyloModule",
      sourceCode: sourceFiles(in: [libraryPath]),
      builtinModuleAccess: true,
      diagnostics: &diagnostics
    )

    let typedProgram = try! TypedProgram(
      annotating: ScopedProgram(ast), inParallel: false,
      reportingDiagnosticsTo: &diagnostics,
      tracingInferenceIf: { (_, _: TypedProgram) in false })

    var db: DocumentationDatabase = .init()

    // Populate the database with some folder information manually:
    let documentationArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/index.hylodoc")!,
        title: "Documentation for Folder1",
        content: .document([.paragraph(Text("lorem ipsum"))])
      ))

    let child1ArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/child1.hylodoc")!,
        title: "Article 1",
        content: .document([.paragraph(Text("This is first child"))])
      ))

    let child2FolderId = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1/Folder2")!,
        documentation: nil,
        children: []
      ))

    // let child3SourceFileId = db.assets.sourceFiles.insert(.init(
    //     fileName: "child2.hylo",
    //     generalDescription: GeneralDescriptionFields(
    //         summary: Block.paragraph(Text("This is second summary")),
    //         description: Block.paragraph(Text("This is second description")),
    //         seeAlso: []
    //     ),
    //     translationUnit: TranslationUnit.ID(3)!
    // ), for: .module("TestHyloModule"))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,  // <- important connection
        // children: [child1ArticleId, child2FolderId, child3SourceFileId]
        children: [AnyAssetID.article(child1ArticleId), AnyAssetID.folder(child2FolderId)]
      ))


    var ctx = GenerationContext(
      documentation: db,
      stencil: createDefaultStencilEnvironment(),
      typedProgram: typedProgram,
      urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
    )

    ctx.urlResolver.resolve(
      target: .asset(.folder(folder1Id)),
      filePath: RelativePath(pathString: "root/Folder1/index.html"), parent: nil)
    ctx.urlResolver.resolve(
      target: .asset(.folder(child2FolderId)),
      filePath: RelativePath(pathString: "root/Folder1/Folder2/index.html"), parent: nil)
    ctx.urlResolver.resolve(
      target: .asset(.article(child1ArticleId)),
      filePath: RelativePath(pathString: "root/Folder1/child1.hylodoc"), parent: nil)

    let res = try! renderFolderPage(ctx: ctx, of: folder1Id)
    let _ = res

    // XCTAssertTrue(res.contains("<title>Folder1</title>"), res)
    // XCTAssertTrue(res.contains("<h1>Folder1</h1>"), res)
    // XCTAssertTrue(res.contains("<h2>Details</h2>"), res)
    // XCTAssertTrue(res.contains("<p>lorem ipsum</p>"), res)
    // XCTAssertTrue(res.contains("<a href=\"child1.hylodoc\""), res)
    // XCTAssertTrue(res.contains("<a href=\"Folder2/index.html\""), res)
  }
}
