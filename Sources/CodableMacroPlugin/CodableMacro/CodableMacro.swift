import Foundation
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Describes a macro that generates `Codable` conformances and implementations.
///
/// This macro performs two different kinds of expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type
///     for the attached struct declaration named `CodingKeys` and use
///     this type for `Codable` implementation of both `init(from:)`
///     and `encode(to:)` methods by using `CodedPropertyMacro`
///     declarations. Additionally member-wise initializer is also generated.
struct CodableMacro: ConformanceMacro, MemberMacro {
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
    ///             member-wise initializer declaration.
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // validate proper use
        guard
            Codable(from: node)!.validate(declaration: declaration, in: context)
        else { return [] }

        let options = Registrar.Options(modifiers: declaration.modifiers)
        var registrar = Registrar(options: options)

        declaration.memberBlock.members.forEach { member in
            // is a variable declaration
            guard let decl = member.decl.as(VariableDeclSyntax.self)
            else { return }

            // build
            let registrations = decl.registrations(node: node, in: context) {
                ExhaustiveRegistrationBuilder(
                    optional: CodedAt(from: decl),
                    fallback: CodedIn(from: decl) ?? CodedIn()
                )
                HelperCodingRegistrationBuilder()
                DefaultCodingRegistrationBuilder<AnyVariable>()
                InitializationRegistrationBuilder<AnyVariable>()
            }

            // register
            for registration in registrations
            where registration.variable.canBeRegistered {
                registrar.add(registration: registration, context: context)
            }
        }

        // generate
        return [
            DeclSyntax(registrar.memberInit(in: context)),
            DeclSyntax(registrar.decoding(in: context)),
            DeclSyntax(registrar.encoding(in: context)),
            DeclSyntax(registrar.codingKeys(in: context)),
        ]
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
