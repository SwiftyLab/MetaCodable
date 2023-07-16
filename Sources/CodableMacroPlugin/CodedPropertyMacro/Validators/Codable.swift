import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `Codable` macro-attribute.
///
/// This type can validate`Codable` macro-attribute
/// usage.
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
