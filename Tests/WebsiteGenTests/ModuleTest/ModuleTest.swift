import XCTest
@testable import WebsiteGen
import Stencil
@testable import DocumentationDB
@testable import FrontEnd

final class DealerTests2: XCTestCase {
    func testModule() {
        print(renderPage(
            Environment(loader: FileSystemLoader(bundle: [Bundle.module])),
            [
                "title": ("Meryl", "{% block title %}{{ title }}{% endblock %}"),
                "name": ("Meryl", "{% block name %}{{ name }}{% endblock %}"),
                "code" : ("<span class=\"text-red-400\">type</span> ArrayList&lt;<span class=\"text-purple-400\">T</span>&gt;", "{% block code %}{{ code }}{% endblock %}"),
                "topics": (["Dancing Queen", "Super Trouper", "Waterloo"], "{% block topics %}{% for topic in topics %}<p>{{ topic }}</p>{% endfor %}{% endblock %}")
            ]
            ))

        let productName = "myProduct"

        let libraryPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("TestHyloModule")

        /// An instance that includes just the standard library.
        var ast = AST(ConditionalCompilationFactors())

        var diagnostics = DiagnosticSet()

        // The module whose Hylo files were given on the command-line
        let _ = try! ast.makeModule(
            productName,
            sourceCode: sourceFiles(in: [libraryPath]),
            builtinModuleAccess: true,
            diagnostics: &diagnostics
        )

        struct ASTWalkingVisitor: ASTWalkObserver {
            var listOfProductTypes: [ProductTypeDecl.ID] = []

            mutating func willEnter(_ n: AnyNodeID, in ast: AST) -> Bool {
            // pattern match the type of node:
            if let d = ProductTypeDecl.ID(n) {
                listOfProductTypes.append(d)
            } else if let d = ModuleDecl.ID(n) {
                let moduleInfo = ast[d]
                print("Module found: " + moduleInfo.baseName)
            } else if let d = TranslationUnit.ID(n) {
                let translationUnit = ast[d]
                print("TU found: " + translationUnit.site.file.baseName)
            } else if let d = FunctionDecl.ID(n) {
                let functionDecl = ast[d]
                print("Function found: " + (functionDecl.identifier?.value ?? "*unnamed*"))
            } else if let d = OperatorDecl.ID(n) {
                let operatorDecl = ast[d]
                print("Operator found: " + operatorDecl.name.value)
            } else if let d = VarDecl.ID(n) {
                let varDecl = ast[d]
                print("VarDecl found: " + varDecl.baseName)
            } else if let d = BindingDecl.ID(n) {
                let bindingDecl = ast[d]
                let _ = bindingDecl
                print("BindingDecl found.")
            }
            return true
            }
        }
        var visitor = ASTWalkingVisitor()
        for m in ast.modules {
            ast.walk(m, notifying: &visitor)
        }

        // get product type by its id
        for productTypeId in visitor.listOfProductTypes {
            let _ = ast[productTypeId]
            // print(productType)
        }

        let typedProgram = try! TypedProgram(
          annotating: ScopedProgram(ast), inParallel: false,
          reportingDiagnosticsTo: &diagnostics,
          tracingInferenceIf: shouldTraceInference)
        func shouldTraceInference(_ n: AnyNodeID, _ p: TypedProgram) -> Bool {
            return true
        }

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

        let stencil = Environment(loader: FileSystemLoader(bundle: [Bundle.module]));

        let ctx = GenerationContext(
            documentation: db,
            stencil: stencil,
            typedProgram: typedProgram
        )

        print(renderModulePage(ctx: ctx, of: db.assetStore.modules[documentationId: parentModuleDocId]!))
    }
}