import PathWrangler

extension RelativePath {

  public func refer(to: RelativePath) -> RelativePath {
    // Get path components
    let fromFile = self.pathString.split(separator: "/")
    let toFile = to.pathString.split(separator: "/")

    // Find how many parts are similar
    var similar = 0
    let maxSimilar = min(fromFile.count, toFile.count) - 1  // the actual file can not be similar
    while similar < maxSimilar && fromFile[similar] == toFile[similar] {
      similar += 1
    }

    // Construct url keeping common parents in mind
    var url = RelativePath(
      pathString: String(repeating: "../", count: fromFile.count - similar - 1))  // Compensate for file name in path
    while similar < toFile.count {
      url = url / String(toFile[similar])
      similar += 1
    }

    return url
  }

}
