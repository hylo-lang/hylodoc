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
    "\(site.gnuStandardText): \(level): \(message)"
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
