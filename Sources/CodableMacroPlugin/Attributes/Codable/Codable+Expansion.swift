import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

extension Codable: ExtensionMacro {
    /// Expand to produce extensions with `Codable` implementation
    /// members for attached struct.
    ///
    /// Depending on whether attached type already conforms to `Decodable`
    /// or `Encodable` extension for `Decodable` or `Encodable` conformance
    /// implementation is skipped.Entire macro expansion is skipped if attached type
    /// already conforms to both `Decodable` and`Encodable`.
    ///
    /// For all the variable declarations in the attached type registration is
    /// done via `Registrar` instance with optional `PeerAttribute`
    /// metadata. The `Registrar` instance provides declarations based on
    /// all the registrations.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - type: The type to provide extensions of.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns:  Extensions with `CodingKeys` type, `Decodable`
    ///   conformance with `init(from:)` implementation and `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let registrar = registrar(for: declaration, node: node, in: context)
        guard let registrar else { return [] }
        return registrar.codableExpansion(for: type, to: protocols, in: context)
    }
}

/// An extension that converts field token syntax
/// to equivalent key token.
extension TokenSyntax {
    /// Convert field token syntax
    /// to equivalent key token
    /// string by trimming \`s`.
    var asKey: String {
        self.text.trimmingCharacters(in: .swiftVariableExtra)
    }

    /// Convert field token syntax
    /// to equivalent key token
    /// by trimming \`s`.
    var raw: TokenSyntax { .identifier(self.asKey) }
}

/// An extension that manages
/// custom character sets
/// for macro expansion.
extension CharacterSet {
    /// Character set that contains extra characters in swift variable names
    /// not applicable for key construction.
    static let swiftVariableExtra: Self = .init(arrayLiteral: "`")
}
