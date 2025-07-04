import SwiftSyntax
import SwiftSyntaxMacros

extension ConformEncodable: MemberMacro, ExtensionMacro {
    /// Expand to produce extensions with `Encodable` implementation
    /// members for attached `class`.
    ///
    /// Conformance for `Encodable` is generated regardless
    /// of whether class already conforms to it. Class or its super class
    /// shouldn't conform to `Encodable`
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Declarations of `CodingKeys` type, `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For types other than `class` types no declarations generated.
    package static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let defaultProtocols: [TypeSyntax] = [
            .init(stringLiteral: TypeCodingLocation.Method.encode.protocol),
        ]
        return try Self.expansion(
            of: node, providingMembersOf: declaration,
            conformingTo: defaultProtocols, in: context
        )
    }

    /// Expand to produce extensions with `Encodable` implementation
    /// members for attached `class`.
    ///
    /// Depending on whether attached type already conforms to `Encodable`,
    /// `Encodable` conformance implementation is skipped.
    /// Entire macro expansion is skipped if attached type already
    /// conforms to `Encodable`.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Declarations of `CodingKeys` type, `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For types other than `class` types no declarations generated.
    package static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let exp = AttributeExpander(for: declaration, in: context)
        else { return [] }
        let type: IdentifierTypeSyntax
        if let decl = declaration.as(ClassDeclSyntax.self) {
            type = .init(name: decl.name)
        } else if let decl = declaration.as(ActorDeclSyntax.self) {
            type = .init(name: decl.name)
        } else {
            return []
        }
        let exts = exp.encodableExpansion(for: type, to: protocols, in: context)
        return exts.flatMap { `extension` in
            `extension`.memberBlock.members.map { DeclSyntax($0.decl) }
        }
    }

    /// Expand to produce extensions with `Encodable` implementation
    /// members for attached `struct` or `class`.
    ///
    /// Depending on whether attached type already conforms to `Encodable`,
    /// extension for `Encodable` conformance implementation is skipped.
    /// Entire macro expansion is skipped if attached type already
    /// conforms to `Encodable`.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
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
    /// - Returns: Extensions with `CodingKeys` type, `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For `class` types only conformance is generated,
    ///   member expansion generates the actual implementation.
    package static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard
            let self = Self(from: node),
            !self.diagnoser().produce(for: declaration, in: context),
            let exp = AttributeExpander(for: declaration, in: context)
        else { return [] }
        var exts = exp.encodableExpansion(for: type, to: protocols, in: context)
        if declaration.is(ClassDeclSyntax.self)
            || declaration.is(ActorDeclSyntax.self)
        {
            for (index, var `extension`) in exts.enumerated() {
                `extension`.memberBlock = .init(members: [])
                exts[index] = `extension`
            }
            exts.removeAll { $0.inheritanceClause == nil }
        }
        return exts
    }
}
