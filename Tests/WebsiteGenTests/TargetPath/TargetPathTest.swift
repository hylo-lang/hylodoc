// import DocumentationDB
// import MarkdownKit
// import PathWrangler
// import StandardLibraryCore
// import Stencil
// import XCTest

// @testable import FrontEnd
// @testable import WebsiteGen

// final class TargetPathTest: XCTestCase {
//   func testFolderPageGenerationWithDetailsWithChildren() {
//     var diagnostics = DiagnosticSet()

//     /// An instance that includes just the standard library.
//     var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

//     // We don't really read anything from here right now, we will the documentation database manually
//     let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
//       .appendingPathComponent("TestHyloModule")

//     // The module whose Hylo files were given on the command-line
//     let _ = try! ast.makeModule(
//       "TestHyloModule",
//       sourceCode: sourceFiles(in: [libraryPath]),
//       builtinModuleAccess: true,
//       diagnostics: &diagnostics
//     )

//     let typedProgram = try! TypedProgram(
//       annotating: ScopedProgram(ast), inParallel: false,
//       reportingDiagnosticsTo: &diagnostics,
//       tracingInferenceIf: { (_, _: TypedProgram) in false })

//     var db: DocumentationDatabase = .init()

//     // Populate the database with some folder information manually:
//     let documentationArticleId = db.assets.articles.insert(
//       .init(
//         location: URL(string: "root/Folder1/index.hylodoc")!,
//         title: "Documentation for Folder1",
//         content: Block.paragraph(Text("lorem ipsum"))
//       ))

//     let child1ArticleId = db.assets.articles.insert(
//       .init(
//         location: URL(string: "root/Folder1/child1.hylodoc")!,
//         title: "Article 1",
//         content: Block.paragraph(Text("This is first child"))
//       ))

//     let child2FolderId = db.assets.folders.insert(
//       .init(
//         location: URL(string: "root/Folder1/Folder2")!,
//         documentation: nil,
//         children: []
//       ))

//     // let child3SourceFileId = db.assets.sourceFiles.insert(.init(
//     //     fileName: "child2.hylo",
//     //     generalDescription: GeneralDescriptionFields(
//     //         summary: Block.paragraph(Text("This is second summary")),
//     //         description: Block.paragraph(Text("This is second description")),
//     //         seeAlso: []
//     //     ),
//     //     translationUnit: TranslationUnit.ID(3)!
//     // ), for: .module("TestHyloModule"))

//     let folder1Id = db.assets.folders.insert(
//       .init(
//         location: URL(string: "root/Folder1")!,
//         documentation: documentationArticleId,  // <- important connection
//         // children: [child1ArticleId, child2FolderId, child3SourceFileId]
//         children: [AnyAssetID.article(child1ArticleId), AnyAssetID.folder(child2FolderId)]
//       ))

//     let ctx = GenerationContext(
//       documentation: db,
//       stencil: createDefaultStencilEnvironment(),
//       typedProgram: typedProgram,
//       urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: ""))
//     )

//     var path: TargetPath = .init(ctx: ctx)

//     // Folder #1
//     path.push(asset: .folder(folder1Id))
//     XCTAssertEqual(path.url, RelativePath(pathString: "Folder1/index.html"))

//     // Folder #1
//     path.push(asset: .folder(child2FolderId))
//     XCTAssertEqual(path.url, RelativePath(pathString: "Folder1/Folder2/index.html"))

//     path.pop()
//     path.push(asset: .article(documentationArticleId))
//     XCTAssertEqual(path.url, RelativePath(pathString: "Folder1/index.article.html"))
//   }
// }
