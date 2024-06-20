/// A set of `Diagnostic` that can answer the question “was there an error?” in O(1).
public struct HDCDiagnosticSet: Error {

  /// The elements of `self`.
  public private(set) var elements: Set<AnyHashable> = []

  /// Whether an error was reported.
  public private(set) var containsError: Bool = false

  /// Creates an empty instance.
  public init() {}

  /// Creates an instance containing the elements of `batch`.
  public init<B: Collection<HDCDiagnostic>>(_ batch: B) {
    formUnion(batch)
  }

  /// Inserts `d` into `self`, returning `true` iff `d` was not already present.
  @discardableResult
  public mutating func insert(_ d: any HDCDiagnostic) -> Bool {
    if d.level == .error { containsError = true }
    return elements.insert(d).inserted
  }

  /// Inserts the elements of `batch`.
  public mutating func formUnion<B: Sequence<HDCDiagnostic>>(_ batch: B) {
    for d in batch { insert(d) }
  }

  /// Inserts the elements of `other`.
  public mutating func formUnion(_ other: Self) {
    elements.formUnion(other.elements)
    containsError = containsError || other.containsError
  }

  /// Throws `self` if any errors were reported.
  public func throwOnError() throws {
    if containsError { throw self }
  }

  /// Whether `self` contains no elements.
  public var isEmpty: Bool { elements.isEmpty }

  public static func isLoggedBefore(_ l: any HDCDiagnostic, _ r: any HDCDiagnostic) -> Bool {
    let lhs = l.site
    let rhs = r.site

    if lhs.file == rhs.file {
      return lhs.startIndex < rhs.startIndex
    } else {
      return lhs.file.url.fileSystemPath.lexicographicallyPrecedes(rhs.file.url.path)
    }
  }

}

extension HDCDiagnosticSet: ExpressibleByArrayLiteral {

  public init(arrayLiteral batch: any HDCDiagnostic...) {
    self.init(batch)
  }

}

extension HDCDiagnosticSet: CustomStringConvertible {

  public var description: String {
    let sortedElements = elements.compactMap { $0 as? any HDCDiagnostic }.sorted {
      HDCDiagnosticSet.isLoggedBefore($0, $1)
    }
    return "\(list: sortedElements, joinedBy: "\n")"
  }

}

extension HDCDiagnosticSet {
  fileprivate var niceErrorMessage: String {
    return "Diagnostics: \n" + elements.map { " - " + $0.description + "\n" }.joined(by: "")
  }
}

extension HDCDiagnosticSet: Equatable {}
