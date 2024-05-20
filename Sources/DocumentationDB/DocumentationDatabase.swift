import Foundation
import FrontEnd

public struct DocumentationDatabase {
  // Assets
  public var assets: AssetStore = .init()

  /// A store of documentation entities of symbols.
  public var symbols: SymbolStore = .init()

  /// The list of modules that we have documentation for.
  public var modules: EntityStore<ModuleInfo> = .init()

  // default initializer public:
  public init() {}
}
