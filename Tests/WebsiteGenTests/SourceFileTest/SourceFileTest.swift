import XCTest
@testable import WebsiteGen
import Stencil
import DocumentationDB
import StandardLibraryCore
import MarkdownKit
import DocExtractor
import PathWrangler

@testable import FrontEnd

func assetNameIs(_ name: String, _ assets: AssetStore) -> ((AnyAssetID) -> Bool) {
  { assets[$0]?.location.lastPathComponent == name }
}

final class SourceFileTest: XCTestCase {
    func unitTestSourceFilePageGeneration() {

        var diagnostics = DiagnosticSet()

        let ast = loadStandardLibraryCore(diagnostics: &diagnostics)

        let typedProgram = try! TypedProgram(
            annotating: ScopedProgram(ast), inParallel: false,
            reportingDiagnosticsTo: &diagnostics,
            tracingInferenceIf: { (_, _) in false })

        let pathUrl = "/Users/evyatarhadasi/Desktop/code/automated-documentation-generation-tool/Tests/WebsiteGenTests/SourceFileTest/TestOutput"
        let ctx = GenerationContext(
                documentation: DocumentationDatabase.init(),
                stencil: Environment(loader: FileSystemLoader(bundle: [Bundle.module])),
                typedProgram: typedProgram,
                urlResolver: URLResolver(baseUrl: AbsolutePath(pathString: pathUrl))
                )

        var res: String = ""

        let sourceFile = SourceFileAsset(
            location: URL(string: "root/Folder1/sf.hylo")!,
            generalDescription: GeneralDescriptionFields(
                summary: .document([.paragraph(Text(
                            "Carving up a summary for dinner, minding my own business."
                        ))]),
                description: .document([.paragraph(Text(
                            "In storms my husband Wilbur in a jealous description. He was crazy!"
                        ))]),
                seeAlso: [
                    .document([.paragraph(Text("And then he ran into my first see also."))]),
                    .document([.paragraph(Text("He ran into my second see also 10 times..."))])
                ]
            ),
            translationUnit: TranslationUnit.ID(rawValue: 2)
        )
        do {
            res = try renderSourceFilePage(ctx: ctx, of: sourceFile)
        } catch {
            XCTFail("Should not throw")
        }

        XCTAssertTrue(res.contains("<p>Carving up a summary for dinner, minding my own business.</p>"), res)
        XCTAssertTrue(res.contains("<p>In storms my husband Wilbur in a jealous description. He was crazy!</p>"), res)
        XCTAssertTrue(res.contains("<p>And then he ran into my first see also.</p>"), res)
        XCTAssertTrue(res.contains("<p>He ran into my second see also 10 times...</p>"), res)
    }

    func integrationTestSourceFilePageGeneration() {

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

        let pathUrl = "/Users/evyatarhadasi/Desktop/code/automated-documentation-generation-tool/Tests/WebsiteGenTests/SourceFileTest/TestOutput"
        let ctx = GenerationContext(
                documentation: db,
                stencil: Environment(loader: FileSystemLoader(bundle: [Bundle.module])),
                typedProgram: typedProgram,
                urlResolver: URLResolver(baseUrl: AbsolutePath(url: URL(fileURLWithPath: pathUrl))!)
                )

        var res: String = ""

        guard let folder1 = db.modules[folder1Id] else {
            return XCTFail("Folder1 not found")
        }

        guard let sfDotHylo = db.assets[folder1.rootFolder]!.children.first(where: assetNameIs("sf.hylo", db.assets)) else {
            return XCTFail("Folder1 root folder should contain sf.hylo")
        }
        
        switch sfDotHylo {
        case .sourceFile(let sid):
            do {
                res = try renderSourceFilePage(ctx: ctx, of: db.assets[sid]!)
                XCTAssertNotNil(db.assets[sid]!.generalDescription.summary, res)
                XCTAssertNotNil(db.assets[sid]!.generalDescription.description, res)
            } catch {
                XCTFail("Should not throw")
            }
        default:
            XCTFail("Folder1 root folder should contain sf.hylo as a source file")
        }

        XCTAssertTrue(res.contains("<p>Carving up a summary for dinner, minding my own business.</p>"), res)
        XCTAssertTrue(res.contains("<p>In storms my husband Wilbur in a jealous description. He was crazy!</p>"), res)
        XCTAssertTrue(res.contains("<p>And then he ran into my first see also.</p>"), res)
        XCTAssertTrue(res.contains("<p>He ran into my second see also 10 times...</p>"), res)
    }
}