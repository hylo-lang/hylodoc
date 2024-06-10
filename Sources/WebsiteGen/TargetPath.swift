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
  case empty
}

public struct TargetPath {
  private var stack: Deque<AnyTargetID> = []
  private var ctx: GenerationContext
  private var symbolCounter = 0

  public init(ctx: GenerationContext) {
    self.ctx = ctx
  }

  /// Generate the url belonging to the current stack
  var url: RelativePath {
    var url = RelativePath(pathString: "")

    // Directory structure
    var index = 0
    while index + 1 < stack.count {
      let target = stack[index]
      index += 1

      if case .asset(let assetId) = target {
        url = url / ctx.documentation.assets[assetId]!.name
      } else if case .symbol(let declId) = target {
        let name = displayNameOfSymbol(ctx: ctx, symbol: declId)
        let parts = name.split(omittingEmptySubsequences: false, whereSeparator: { $0 == " " })
        url = url / String(parts.last!)
      }
    }

    guard let lastTarget = stack.last else {
      return url
    }

    if case .asset(let assetId) = lastTarget {
      if case .article(_) = assetId {
        let name = ctx.documentation.assets[assetId]!.name
        let parts = name.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "." })
        return url / (String(parts.first!) + ".html")
      } else if case .otherFile(_) = assetId {
        return url / ctx.documentation.assets[assetId]!.name
      }

      return url / ctx.documentation.assets[assetId]!.name / "index.html"
    } else if case .symbol(let declId) = lastTarget {
      let name = displayNameOfSymbol(ctx: ctx, symbol: declId)
      let parts = name.split(omittingEmptySubsequences: false, whereSeparator: { $0 == " " })
      return url / String(parts.last!) / "index.html"
    }

    return url
  }

  /// Get the parent of the current target
  var parent: AnyTargetID? {
    if stack.count < 2 {
      return nil
    }

    return stack[stack.count - 2]
  }

  /// Get the current target
  var target: AnyTargetID {
    return stack.last!
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
