import Foundation
import FrontEnd

public struct DocumentationDatabase {
  // Assets
  public var assetStore: AssetStore = .init()

  /// A store of documentation entities of symbols.
  public var symbols: SymbolStore = .init()

  /// A store of markdown nodes that can be referenced by ID.
  public var markdownStore: MarkdownStore = .init()
}
