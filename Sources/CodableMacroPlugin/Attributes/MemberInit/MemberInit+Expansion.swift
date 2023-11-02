@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

extension MemberInit: MemberMacro {
    /// Expand to produce memberwise initializer(s) for attached struct.
    ///
    /// For all the variable declarations in the attached type registration is
    /// done via `Registrar` instance with optional `PropertyAttribute`
    /// metadata. The `Registrar` instance provides declarations based on
    /// all the registrations.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Memberwise initializer(s) declaration(s).
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let registrar = registrar(for: declaration, node: node, in: context)
        guard let registrar else { return [] }
        return registrar.memberInit(in: context).map { DeclSyntax($0) }
    }
}
