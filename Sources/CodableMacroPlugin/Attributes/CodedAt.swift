import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `CodedAt` macro-attribute.
///
/// This type can validate`CodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAt: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The attribute types this attribute can't be combined with.
    ///
    /// If any of the attribute type that is covered in this is applied in the same
    /// declaration as this attribute is attached, then diagnostics generated
    /// to remove this attribute.
    ///
    /// - Note: This attribute can't be combined with `CodedIn`
    ///         macro-attribute.
    var cantBeCombinedWith: [PropertyAttribute.Type] {
        return [
            CodedIn.self
        ]
    }
    /// Creates a new instance with the provided node.
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
    /// The following conditions are checked for validations:
    /// * Attached declaration is a variable declaration.
    /// * Attached declaration is not a grouped variable declaration.
    /// * This attribute isn't used combined with `CodedIn` attribute.
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
        let result = performBasicValidation(of: declaration, in: context)
        var diagnostics: [(MetaCodableMessage, [FixIt])] = []

        if declaration.as(VariableDeclSyntax.self)?.bindings.count ?? 0 > 1 {
            let message = node.diagnostic(
                message:
                    "@\(name) can't be used with grouped variables declaration",
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

        return result && diagnostics.isEmpty
    }
}
