import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

enum MacroError: CustomStringConvertible, Error {
  case onlyApplicableToStruct

  var description: String {
    switch self {
    case .onlyApplicableToStruct:
      return "@Diagnostify can only be applied to a struct."
    }
  }
}

public struct DiagnostifyMacro {}

extension DiagnostifyMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      throw MacroError.onlyApplicableToStruct
    }

    let existingConformances =
      structDecl.inheritanceClause?.inheritedTypes.map { $0.type.trimmedDescription } ?? []
    if existingConformances.contains("HDCDiagnostic") {
      return []
    }

    return try [ExtensionDeclSyntax("extension \(type.trimmed): HDCDiagnostic {}")]
  }
}

extension DiagnostifyMacro: MemberMacro {
  public static func expansion(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let _ = declaration.as(StructDeclSyntax.self) else {
      throw MacroError.onlyApplicableToStruct
    }

    return [
      """
      public let level: HDCDiagnosticLevel
      public let message: String
      public let site: SourceRange
      public let notes: [AnyHashable]

      public init(level: HDCDiagnosticLevel, message: String, site: SourceRange, notes: [AnyHashable] = []) {
        self.level = level
        self.message = message
        self.site = site
        self.notes = notes
      }

      public static func note(_ message: String, at site: SourceRange) -> Self {
        Self(level: .note, message: message, site: site)
      }

      public static func error(
        _ message: String, at site: SourceRange, notes: [AnyHashable] = []
      ) -> Self {
        Self(level: .error, message: message, site: site, notes: notes)
      }

      public static func warning(
        _ message: String, at site: SourceRange, notes: [AnyHashable] = []
      ) -> Self {
        Self(level: .warning, message: message, site: site, notes: notes)
      }

      """
    ]
  }
}

@main
struct HDCMacros: CompilerPlugin {
  var providingMacros: [Macro.Type] = [DiagnostifyMacro.self]
}
