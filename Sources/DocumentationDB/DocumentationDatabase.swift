import Foundation
import FrontEnd

public struct DocumentationDatabase {
  // Assets
  public var assetStore: AssetStore = .init()

  /// A store of documentation entities of symbols.
  public var symbols: SymbolStore = .init()
}
