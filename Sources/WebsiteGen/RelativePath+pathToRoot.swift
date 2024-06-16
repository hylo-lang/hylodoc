import Foundation
import PathWrangler

extension RelativePath {

  public var pathToRoot: RelativePath {
    let depth = self.resolved().pathString.filter { $0 == "/" }.count
    return RelativePath(pathString: String(repeating: "../", count: depth))
  }

}
