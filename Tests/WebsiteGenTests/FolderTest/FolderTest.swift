import DocumentationDB
import MarkdownKit
import PathWrangler
import HyloStandardLibrary
import Stencil
import TestUtils
import XCTest

@testable import FrontEnd
@testable import WebsiteGen

final class FolderTest: XCTestCase {
  func testFolderPageGenerationNoDetailsNoChildren() throws {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = try AST.loadStandardLibraryCore(diagnostics: &diagnostics)

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
        children: [],
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.folder(folder1Id))

    // folder1Id
    let partialResolvedParent = partialResolveAsset(db, typedProgram, assetId: .folder(folder1Id))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolvedParent.simpleName,
        navigationName: partialResolvedParent.navigationName,
        children: partialResolvedParent.children,
        relativePath: RelativePath(pathString: "root/Folder1/index.html")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: [],
      tree: []
    )

    let stencilContext = try prepareFolderPage(context, of: folder1Id)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("Folder1", in: res)

    assertNotContains("content", what: res)
    assertNotContains("contents", what: res)
  }

  func testFolderPageGenerationWithDetailsNoChildren() throws {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = try AST.loadStandardLibraryCore(diagnostics: &diagnostics)

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
        content: .document([.paragraph(Text("lorem ipsum"))]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,
        children: [],
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.folder(folder1Id))

    // folder1Id
    let partialResolvedParent = partialResolveAsset(db, typedProgram, assetId: .folder(folder1Id))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolvedParent.simpleName,
        navigationName: partialResolvedParent.navigationName,
        children: partialResolvedParent.children,
        relativePath: RelativePath(pathString: "root/Folder1/index.html")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: [],
      tree: []
    )

    let stencilContext = try prepareFolderPage(context, of: folder1Id)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("Info Article", in: res)
    assertContent("lorem ipsum", in: res)

    assertNotContains("Folder1", what: res)
    assertNotContains("contents", what: res)
  }

  func testFolderPageGenerationWithDetailsWithChildren() throws {

    var diagnostics = DiagnosticSet()

    /// An instance that includes just the standard library.
    var ast = try AST.loadStandardLibraryCore(diagnostics: &diagnostics)

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
        content: .document([.paragraph(Text("lorem ipsum"))]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let child1ArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/child1.hylodoc")!,
        title: "First News",
        content: .document([.paragraph(Text("This is first child"))]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let child2FolderId = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1/Folder2")!,
        documentation: nil,
        children: [],
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,  // <- important connection
        children: [AnyAssetID.article(child1ArticleId), AnyAssetID.folder(child2FolderId)],
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.folder(folder1Id))

    // child1ArticleId
    let partialResolvedChild1 = partialResolveAsset(
      db, typedProgram, assetId: .article(child1ArticleId))
    targetResolver.resolve(
      targetId: .asset(.article(child1ArticleId)),
      ResolvedTarget(
        id: .asset(.article(child1ArticleId)),
        parent: .asset(.folder(folder1Id)),
        simpleName: partialResolvedChild1.simpleName,
        navigationName: partialResolvedChild1.navigationName,
        children: partialResolvedChild1.children,
        relativePath: RelativePath(pathString: "root/Folder1/child1.hylodoc")
      )
    )

    // child2FolderId
    let partialResolvedChild2 = partialResolveAsset(
      db, typedProgram, assetId: .folder(child2FolderId))
    targetResolver.resolve(
      targetId: .asset(.folder(child2FolderId)),
      ResolvedTarget(
        id: .asset(.folder(child2FolderId)),
        parent: targetId,
        simpleName: partialResolvedChild2.simpleName,
        navigationName: partialResolvedChild2.navigationName,
        children: partialResolvedChild2.children,
        relativePath: RelativePath(pathString: "root/Folder1/Folder2/index.html")
      )
    )

    // folder1Id
    let partialResolvedParent = partialResolveAsset(db, typedProgram, assetId: .folder(folder1Id))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolvedParent.simpleName,
        navigationName: partialResolvedParent.navigationName,
        children: partialResolvedParent.children,
        relativePath: RelativePath(pathString: "root/Folder1/index.html")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: [],
      tree: []
    )

    let stencilContext = try prepareFolderPage(context, of: folder1Id)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("Info Article", in: res)
    assertContent("lorem ipsum", in: res)
    assertListExistAndCount(id: "contents", count: 2, in: res)

    assertNotContains("Folder1", what: res)
  }

  func testFolderPageGenerationWithInternalDetailsWithInternalChildren() throws {

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
        location: URL(string: "root/Folder1/index.internal.hylodoc")!,
        title: "Info Article",
        content: .document([.paragraph(Text("lorem ipsum"))]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let child1ArticleId = db.assets.articles.insert(
      .init(
        location: URL(string: "root/Folder1/child1.internal.hylodoc")!,
        title: "First News",
        content: .document([.paragraph(Text("This is first child"))]),
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    let folder1Id = db.assets.folders.insert(
      .init(
        location: URL(string: "root/Folder1")!,
        documentation: documentationArticleId,  // <- important connection
        children: [AnyAssetID.article(child1ArticleId)],
        moduleId: ModuleDecl.ID(rawValue: 0)
      ))

    var targetResolver: TargetResolver = .init()
    let targetId: AnyTargetID = .asset(.folder(folder1Id))

    // folder1Id
    let partialResolvedParent = partialResolveAsset(db, typedProgram, assetId: .folder(folder1Id))
    targetResolver.resolve(
      targetId: targetId,
      ResolvedTarget(
        id: targetId,
        parent: nil,
        simpleName: partialResolvedParent.simpleName,
        navigationName: partialResolvedParent.navigationName,
        children: partialResolvedParent.children,
        relativePath: RelativePath(pathString: "root/Folder1/index.html")
      )
    )

    var context = GenerationContext(
      documentation: DocumentationContext(
        documentation: db,
        typedProgram: typedProgram,
        targetResolver: targetResolver
      ),
      stencilEnvironment: createDefaultStencilEnvironment(),
      exporter: DefaultExporter(AbsolutePath.current),
      breadcrumb: [],
      tree: []
    )

    let stencilContext = try prepareFolderPage(context, of: folder1Id)
    let res = try renderPage(&context, stencilContext, of: targetId)

    assertPageTitle("Folder1", in: res)
    assertNotContains("content", what: res)
    assertNotContains("contents", what: res)
  }
}
