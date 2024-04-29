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
}
