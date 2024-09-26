import SwiftSyntax
import SwiftSyntaxMacros

/// Dummy implementation of swift-testing `Test` macro.
struct Test: PeerMacro {
    /// Dummy implementation of swift-testing `Test` macro.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

/// Dummy implementation of swift-testing `Tag` macro.
struct Tag: AccessorMacro {
    /// Dummy implementation of swift-testing `Tag` macro.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Returns getter declaration with `fatalError`.
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        return [
            AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
                "fatalError(\"Unreachable\")"
            }
        ]
    }
}
