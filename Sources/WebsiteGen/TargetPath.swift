import Foundation
import FrontEnd
import DocumentationDB
import DequeModule

/// An identifier that uniquely identifies an asset or symbol in a path
///
/// It stores the type (asset or symbol) and the local ID of the value within that type.
/// (It is a composite key.)
public enum AnyTargetID : Equatable, Hashable {
  case asset(AnyAssetID)
  case symbol(AnyDeclID)
}

public struct TargetPath {
    private var stack: Deque<AnyTargetID> = []
    private var ctx: GenerationContext
    private var symbolCounter = 0
    
    public init(ctx: GenerationContext) {
        self.ctx = ctx
    }
    
    // Push asset onto stack
    public mutating func push(asset: AnyAssetID) {
        stack.append(.asset(asset))
        
        // Reset symbol counter for source file
        if case .sourceFile(_) = asset {
            symbolCounter = 0
        }
    }
    
    // Push symbol onto stack
    public mutating func push(decl: AnyDeclID) {
        stack.append(.symbol(decl))
        
        // Increase symbol counter for new symbol
        symbolCounter += 1
    }
    
    // Pop top-item on the stack
    public mutating func pop() {
        let _ = stack.popLast()
    }
    
    // Get the current target
    public func target() -> AnyTargetID {
        return stack.last!
    }
    
    // Get how many directories deep the path is
    public func depth() -> Int {
        var index = 0
        while index < stack.count, case .asset(_) = stack[index] {
            index += 1
        }
        
        return index
    }
    
    // Generate the url belonging to the current stack
    public func url() -> URL {
        var url = URL(fileURLWithPath: "")
        
        var index = 0
        while index < stack.count, case .asset(let id) = stack[index] {
            url.appendPathComponent(convertAssetToPath(ctx: ctx, asset: id, last: (index + 1 == stack.count)))
            index += 1
        }
        
        if(index + 1 < stack.count) {
            // symbol name as part of url?
            url.appendPathComponent("symbol-\(symbolCounter).html")
        }
        
        return url
    }
    
}

private func convertAssetToPath(ctx: GenerationContext, asset: AnyAssetID, last: Bool) -> String {
    switch asset {
    case .folder(let id):
        let folder = ctx.documentation.assets.folders[id]!
        return folder.name + (last ? "/index.html" : "")
    case .sourceFile(let id):
        let sourceFile = ctx.documentation.assets.sourceFiles[id]!
        let translationUnit = ctx.typedProgram.ast[sourceFile.translationUnit]!
        return translationUnit.site.file.baseName + (last ? "/index.html" : "")
    case .article(let id):
        let article = ctx.documentation.assets.articles[id]!
        return article.name
    case .otherFile(let id):
        let otherFile = ctx.documentation.assets.otherFiles[id]!
        return otherFile.name
    }
}
