import Foundation
import FrontEnd

public struct DocumentationDatabase {
  // Assets
  public var assets: AssetStore = .init()

  /// A store of documentation entities of symbols.
  public var symbols: SymbolDocStore = .init()

  /// The list of modules that we have documentation for.
  public var modules: AdaptedEntityStore<ModuleDecl, ModuleInfo> = .init()

  public init() {}

  public init(
    assets: AssetStore, symbols: SymbolDocStore, modules: AdaptedEntityStore<ModuleDecl, ModuleInfo>
  ) {
    self.assets = assets
    self.symbols = symbols
    self.modules = modules
  }
}
