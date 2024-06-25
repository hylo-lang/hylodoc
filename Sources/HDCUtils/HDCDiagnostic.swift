import Foundation
import FrontEnd

public protocol HDCDiagnostic: Hashable, CustomStringConvertible {
  var level: HDCDiagnosticLevel { get }
  var message: String { get }
  var site: SourceRange { get }
  var notes: [AnyHashable] { get }
}

public enum HDCDiagnosticLevel: Hashable {
  case note
  case warning
  case error
}

extension HDCDiagnostic {
  public var description: String {
    "\(site.vscodeFriendlyDescription): \(level): \(message)"
  }
}

@attached(
  member,
  names:
    named(level),
  named(message),
  named(site),
  named(notes),
  named(init(level:message:site:notes:)),
  named(note(_:at:)),
  named(error(_:at:notes:)),
  named(warning(_:at:notes:))
)
@attached(extension, conformances: HDCDiagnostic)
public macro Diagnostify() = #externalMacro(module: "HDCMacros", type: "DiagnostifyMacro")

extension SourceRange {

  /// A textual representation per the
  /// [Gnu-standard](https://www.gnu.org/prep/standards/html_node/Errors.html).
  public var vscodeFriendlyDescription: String {
    let start = self.start.lineAndColumn
    let head = "\(file.url.relativePath):\(start.line):\(start.column)"
    if regionOfFile.isEmpty { return head }

    let end = file.position(endIndex).lineAndColumn
    if end.line == start.line {
      return head + "-\(end.column)"
    }
    return head + "-\(end.line):\(end.column)"
  }

  public var description: String { gnuStandardText }

}
