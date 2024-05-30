import DequeModule
import DocumentationDB
import Foundation
import FrontEnd
import PathWrangler

/// An identifier that uniquely identifies an asset or symbol in a path
///
/// It stores the type (asset or symbol) and the local ID of the value within that type.
/// (It is a composite key.)
public enum AnyTargetID: Equatable, Hashable {
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

  // Generate the url belonging to the current stack
  var url: RelativePath {
    var url = RelativePath(pathString: "")

    // Directory structure
    var index = 0
    while index < stack.count, case .asset(let id) = stack[index] {
      url = url / convertAssetToPath(ctx: ctx, asset: id)
      index += 1
    }

    if index + 1 <= stack.count {
      // symbol name as part of url?
      // counter for symbols
      url = url / "symbol-\(symbolCounter).html"
    } else if case .asset(let id) = stack[index - 1] {
      if case .folder(_) = id {
        // append index.html for folder since that has a nested structure
        url = url / "index.html"
      } else if case .sourceFile(_) = id {
        // append index.html for sourceFile since that has a nested structure
        url = url / "index.html"
      }
    }

    return url
  }

  /// Push asset onto stack
  public mutating func push(asset: AnyAssetID) {
    stack.append(.asset(asset))

    // Reset symbol counter for source file
    if case .sourceFile(_) = asset {
      symbolCounter = 0
    }
  }

  /// Push symbol onto stack
  public mutating func push(decl: AnyDeclID) {
    stack.append(.symbol(decl))

    // Increase symbol counter for new symbol
    symbolCounter += 1
  }

  /// Pop top-item on the stack
  public mutating func pop() {
    let _ = stack.popLast()
  }

  /// Get the current target
  public func target() -> AnyTargetID {
    return stack.last!
  }

}

private func convertAssetToPath(ctx: GenerationContext, asset: AnyAssetID) -> String {
  switch asset {
  case .folder(let id):
    let folder = ctx.documentation.assets.folders[id]!
    return folder.name
  case .sourceFile(let id):
    let sourceFile = ctx.documentation.assets.sourceFiles[id]!
    return String(sourceFile.name.lazy.split(separator: ".")[0])
  case .article(let id):
    let article = ctx.documentation.assets.articles[id]!
    return String(article.name.lazy.split(separator: ".")[0])
      + ".article.html"
  case .otherFile(let id):
    let otherFile = ctx.documentation.assets.otherFiles[id]!
    return otherFile.name
  }
}
