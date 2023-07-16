import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Describes a macro that provides metadata to `CodableMacro`
/// for individual variable decoding approaches.
///
/// This macro doesn't perform any expansion rather `CodableMacro`
/// uses when performing expansion.
///
/// This macro can be used by multiple macro attributes,
/// each attribute having their own validator(s)
/// confirming to `Attribute`.
///
/// This macro verifies that macro usage condition is met by attached declaration
/// by using the `validators` provided. If not, then this macro generates
/// diagnostic to remove it.
struct CodedPropertyMacro: PeerMacro {
    /// The validators that validate macro usage.
    ///
    /// This macro can be used by multiple macro attributes,
    /// each attribute having their own validator(s)
    /// confirming to `Attribute`.
    static let validators: [Attribute.Type] = [
        CodedAt.self,
        CodedIn.self,
    ]

    /// Provide metadata to `CodableMacro` for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `CodableMacro`
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached declaration
    /// by using the `validators` provided. If not, then this macro generates
    /// diagnostic to remove it.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        validators.lazy
            .compactMap { $0.init(from: node) }
            .forEach { $0.validate(declaration: declaration, in: context) }
        return []
    }
}
