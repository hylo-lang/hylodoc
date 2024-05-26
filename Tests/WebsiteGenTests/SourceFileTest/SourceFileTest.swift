import XCTest
@testable import WebsiteGen
import Stencil
import DocumentationDB
import StandardLibraryCore
import MarkdownKit
import DocExtractor

@testable import FrontEnd

func assetNameIs(_ name: String, _ assets: AssetStore) -> ((AnyAssetID) -> Bool) {
  { assets[$0]?.location.lastPathComponent == name }
}

final class SourceFileTest: XCTestCase {
    func testSourceFilePageGeneration() {

        var diagnostics = DiagnosticSet()

        var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        let baseUrl = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let folder1Path = baseUrl.appendingPathComponent("Folder1")

        let folder1Id = try! ast.makeModule(
            "Folder1", sourceCode: sourceFiles(in: [folder1Path]), builtinModuleAccess: true,
            diagnostics: &diagnostics)
        
        XCTAssert(diagnostics.isEmpty, diagnostics.description)

        let typedProgram = try! TypedProgram(
            annotating: ScopedProgram(ast), inParallel: false,
            reportingDiagnosticsTo: &diagnostics,
            tracingInferenceIf: { (_, _) in false })

        XCTAssert(diagnostics.isEmpty, diagnostics.description)
        
        // WHEN trying to extract documentation
        
        let result = extractDocumentation(typedProgram: typedProgram, for: [
            .init(name: "Folder1", rootFolderPath: folder1Path, astId: folder1Id),
        ])
        
        // THEN the documentation should be extracted successfully
        switch result {
        case .failure(let error):
            XCTFail("Failed to extract documentation: \(error)")
        default:
            break
        }

        let db = try! result.get()

        let ctx = GenerationContext(
                documentation: db,
                stencil: Environment(loader: FileSystemLoader(bundle: [Bundle.module])),
                typedProgram: typedProgram
                )

        var res: String = ""

        // guard let folder1 = db.modules[folder1Id] else {
        //     return XCTFail("Folder1 not found")
        // }

        // guard let sfDotHylo = db.assets[folder1.rootFolder]!.children.first(where: assetNameIs("sf.hylo", db.assets)) else {
        //     return XCTFail("Folder1 root folder should contain sf.hylo")
        // }
        
        // switch sfDotHylo {
        // case .sourceFile(let sid):
        //     do {
        //         res = try renderSourceFilePage(ctx: ctx, of: db.assets[sid]!)
        //     } catch {
        //         XCTFail("Should not throw")
        //     }
        // default:
        //     XCTFail("Folder1 root folder should contain sf.hylo as a source file")
        // }

        // do {
        // } catch {
        //     XCTFail("Should not throw")
        // }
        let sourceFile = SourceFileAsset(
            location: URL(string: "root/Folder1/sf.hylo")!,
            generalDescription: GeneralDescriptionFields(
                summary: Block.paragraph(Text("This is the summary")),
                description: Block.paragraph(Text("This is the description")),
                seeAlso: [
                    Block.paragraph(Text("see also #1")),
                    Block.paragraph(Text("second see also"))
                ]
            ),
            // translationUnit: TranslationUnit.ID(try AnyNodeID(from: 2 as! Decoder))!
            translationUnit: TranslationUnit.ID(rawValue: 2)
        )
        do {
            res = try renderSourceFilePage(ctx: ctx, of: sourceFile)
        } catch {
            XCTFail("Should not throw")
        }

        print(res)
    }

    // func testSourceFilePageGeneration() {

    //     var diagnostics = DiagnosticSet()

    //     /// An instance that includes just the standard library.
    //     var ast = loadStandardLibraryCore(diagnostics: &diagnostics)

    //     // We don't really read anything from here right now, we will the documentation database manually
    //     let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    //         .appendingPathComponent("TestHyloSourceFile")

    //     // The module whose Hylo files were given on the command-line
    //     let _ = try! ast.makeModule(
    //         "TestHyloSourceFile",
    //         sourceCode: sourceFiles(in: [libraryPath]),
    //         builtinModuleAccess: true,
    //         diagnostics: &diagnostics
    //     )

    //     let typedProgram = try! TypedProgram(
    //       annotating: ScopedProgram(ast), inParallel: false,
    //       reportingDiagnosticsTo: &diagnostics,
    //       tracingInferenceIf: { (_,_: TypedProgram) in false })
        
    //     var db: DocumentationDatabase = .init()


    //     let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));

    //     let ctx = GenerationContext(
    //         documentation: db,
    //         stencil: stencil,
    //         typedProgram: typedProgram
    //     )

    //     let folder1Id = db.assets.folders.insert(.init(
    //         location: URL(string: "root/Folder1")!,
    //         documentation: nil,
    //         children: []
    //     ))

    //     var res: String = ""
    //     do {
    //         res = try renderFolderPage(ctx: ctx, of: db.assets.folders[folder1Id]!)
    //     } catch {
    //         XCTFail("Should not throw")
    //     }

    //     XCTAssertTrue(res.contains("<title>Documentation - Folder1</title>"), res)
    //     XCTAssertTrue(res.contains("<h1>Folder1</h1>"), res)
        
    //     XCTAssertFalse(res.contains("<h2>Overview</h2>"), res)
    // }
}