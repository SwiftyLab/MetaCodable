import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

extension Codable: ConformanceMacro, MemberMacro {
    /// Expand to produce `Codable` conformance.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: `Codable` type to allow conformance to both
    ///            `Decodable` and `Encodable` protocols
    ///            without any where clause.
    static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [
            ("Codable", nil)
        ]
    }

    /// Expand to produce `Codable` implementation members for attached struct.
    ///
    /// For all the variable declarations in the attached type registration is
    /// done via `Registrar` instance with optional `CodedPropertyMacro`
    /// metadata. The `Registrar` instance provides declarations based on
    /// all the registrations.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: `CodingKeys` type and `init(from:)`, `encode(to:)`,
    ///             method declarations for `Codable` implementation along with
    ///             member-wise initializer declaration(s).
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // validate proper use
        guard
            let self = Self(from: node),
            !self.diagnoser().produce(for: declaration, in: context)
        else { return [] }

        let options = Registrar.Options(modifiers: declaration.modifiers)
        var registrar = Registrar(options: options)

        declaration.memberBlock.members.forEach { member in
            // is a variable declaration
            guard let decl = member.decl.as(VariableDeclSyntax.self)
            else { return }

            // builder
            let builder = IgnoreCodingInitialized(from: declaration)
            |> KeyPathRegistrationBuilder(
                provider: CodedAt(from: decl)
                ?? CodedIn(from: decl)
                ?? CodedIn()
            )
            |> HelperCodingRegistrationBuilder()
            |> DefaultCodingRegistrationBuilder()
            |> InitializationRegistrationBuilder()
            |> IgnoreCodingBuilder()

            // build
            let regs = decl.registrations(for: self, in: context, with: builder)

            // register
            for registration in regs {
                registrar.add(registration: registration, context: context)
            }
        }

        // generate
        return registrar.memberDeclarations(in: context)
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
