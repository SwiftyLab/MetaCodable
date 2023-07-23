import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// An `Attribute` type that can be applied to property declaration.
///
/// This macro doesn't perform any expansion rather `CodableMacro`
/// uses when performing expansion.
///
/// This macro verifies that macro usage condition is met by attached
/// declaration by using the `diagnoser().produce(syntax:in:)` implementation.
/// If verification fails, then this macro generates diagnostic to remove it.
protocol PropertyAttribute: Attribute, PeerMacro {}

extension PropertyAttribute {
    /// Create a new instance from provided attached
    /// variable declaration.
    ///
    /// This initialization will fail if this attribute not attached
    /// to provided variable declaration
    ///
    /// - Parameter declaration: The attached variable
    ///                          declaration.
    /// - Returns: Created registration builder attribute.
    init?(from declaration: VariableDeclSyntax) {
        let attribute = declaration.attributes?.first { attribute in
            guard case .attribute(let attribute) = attribute
            else { return false }
            return Self(from: attribute) != nil
        }
        guard case .attribute(let attribute) = attribute else { return nil }
        self.init(from: attribute)
    }

    /// Provide metadata to `CodableMacro` for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `CodableMacro`
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
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
        Self(from: node)!.diagnoser().produce(for: declaration, in: context)
        return []
    }
}
