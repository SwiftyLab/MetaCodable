import Foundation
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `Codable` macro-attribute.
///
/// Describes a macro that validates `Codable` macro usage
/// and generates `Codable` conformances and implementations.
///
/// This macro performs two different kinds of expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type
///     for the attached struct declaration named `CodingKeys` and use
///     this type for `Codable` implementation of both `init(from:)`
///     and `encode(to:)` methods by using `CodedPropertyMacro`
///     declarations. Additionally member-wise initializer(s) also generated.
struct Codable: Attribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax
    /// Creates a new instance with the provided node
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax) {
        guard
            node.attributeName.as(SimpleTypeIdentifierSyntax.self)!
                .description == Self.name
        else { return nil }
        self.node = node
    }

    /// Validates this attribute is used properly with the declaration provided.
    ///
    /// The declaration has to be a `struct` declaration, otherwise validation fails
    /// and diagnostics created with `misuseMessageID`.
    ///
    /// - Parameters:
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The macro expansion context validation performed in.
    ///
    /// - Returns: True if attribute usage satisfies all conditions,
    ///            false otherwise.
    @discardableResult
    func validate(
        declaration: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        var diagnostics: [(MetaCodableMessage, [FixIt])] = []

        if !declaration.is(StructDeclSyntax.self) {
            let message = node.diagnostic(
                message: "@\(name) only works for struct declarations",
                id: misuseMessageID,
                severity: .error
            )
            diagnostics.append((message, [message.fixItByRemove]))
        }

        for (message, fixes) in diagnostics {
            context.diagnose(
                .init(
                    node: Syntax(node),
                    message: message,
                    fixIts: fixes
                )
            )
        }
        return diagnostics.isEmpty
    }
}

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
        guard Self(from: node)!.validate(declaration: declaration, in: context)
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
                OptionalRegistrationBuilder(base: CodedBy(from: decl))
                OptionalRegistrationBuilder(base: Default(from: decl))
                InitializationRegistrationBuilder<AnyVariable>()
            }

            // register
            for registration in registrations
            where registration.variable.canBeRegistered {
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
