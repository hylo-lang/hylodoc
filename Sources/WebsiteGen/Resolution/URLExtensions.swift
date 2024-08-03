import Foundation

extension URL {

  /// Returns the URL with the given anchor string added at the end (e.g. `#sectionName`)
  func addingAnchor(anchor: String) -> URL? {
    var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
    urlComponents?.fragment = anchor
    return urlComponents?.url
  }

  /// Given `from` as a base, returns the relative path to the given (possibly longer) URL.
  /// 
  /// - Returns: The relative path, or nil if the given URL is not a subpath of self.
  func relativeInwardsPath(from: URL) -> ArraySlice<String>? {
    let base = from.standardized.absoluteURL
    let longer = self.standardized.absoluteURL

    guard longer.pathComponents.starts(with: base.pathComponents) else {
      return nil
    }

    return longer.pathComponents[base.pathComponents.count...]
  }

  /// Returns the URL with the given path components appended.
  func appendingPathComponents(_ sequence: some Sequence<String>) -> URL {
    return sequence.reduce(self) { url, component in
      url.appendingPathComponent(component)
    }
  }
}
