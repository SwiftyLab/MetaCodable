import SwiftSyntax
import SwiftSyntaxMacros

extension MemberInit: MemberMacro {
    /// Expand to produce memberwise initializer(s) for attached struct.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Memberwise initializer(s) declaration(s).
    package static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let self = Self(from: node),
            !self.diagnoser().produce(for: declaration, in: context),
            let expander = AttributeExpander(for: declaration, in: context)
        else { return [] }
        return expander.memberInit(in: context).map { DeclSyntax($0) }
    }

    /// Expand to produce memberwise initializer(s) for attached struct.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Memberwise initializer(s) declaration(s).
    package static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try Self.expansion(
            of: node, providingMembersOf: declaration, in: context
        )
    }
}
