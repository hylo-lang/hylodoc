import DocumentationDB
import MarkdownKit
import PathWrangler
import StandardLibraryCore
import Stencil
import XCTest
import TestUtils

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
        urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
        htmlGenerator: CustomHTMLGenerator(),
        tree: []
    )

    ctx.urlResolver.resolve(target: .asset(.folder(folder1Id)), filePath: RelativePath(pathString: "root/Folder1/index.html"), parent: nil)

    let res = try! renderFolderPage(ctx: &ctx, of: folder1Id)

    assertPageTitle("Folder1", in: res, file: #file, line: #line)

    assertNotContains("content", what: res, file: #file, line: #line)
    assertNotContains("contents", what: res, file: #file, line: #line)
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
        title: "Info Article",
        content: .document([.paragraph(Text("lorem ipsum"))])
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,
        children: []
      ))

    var ctx = GenerationContext(
        documentation: db,
        stencil: createDefaultStencilEnvironment(),
        typedProgram: typedProgram,
        urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
        htmlGenerator: CustomHTMLGenerator(),
        tree: []
    )

    ctx.urlResolver.resolve(target: .asset(.folder(folder1Id)), filePath: RelativePath(pathString: "root/Folder1/index.html"), parent: nil)

    let res = try! renderFolderPage(ctx: &ctx, of: folder1Id)

    assertPageTitle("Info Article", in: res, file: #file, line: #line)
    assertContent("lorem ipsum", in: res, file: #file, line: #line)

    assertNotContains("Folder1", what: res, file: #file, line: #line)
    assertNotContains("contents", what: res, file: #file, line: #line)
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
        title: "Info Article",
        content: .document([.paragraph(Text("lorem ipsum"))])
      ))

    let child1ArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/child1.hylodoc")!,
        title: "First News",
        content: .document([.paragraph(Text("This is first child"))])
      ))

    let child2FolderId = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1/Folder2")!,
        documentation: nil,
        children: []
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,  // <- important connection
        children: [AnyAssetID.article(child1ArticleId), AnyAssetID.folder(child2FolderId)]
      ))

    var ctx = GenerationContext(
        documentation: db,
        stencil: createDefaultStencilEnvironment(),
        typedProgram: typedProgram,
        urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: "")),
        htmlGenerator: CustomHTMLGenerator(),
        tree: []
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

    let res = try! renderFolderPage(ctx: &ctx, of: folder1Id)

    assertPageTitle("Info Article", in: res, file: #file, line: #line)
    assertContent("lorem ipsum", in: res, file: #file, line: #line)
    assertListExistAndCount(id: "contents", count: 2, in: res, file: #file, line: #line)

    assertNotContains("Folder1", what: res, file: #file, line: #line)
  }
}
