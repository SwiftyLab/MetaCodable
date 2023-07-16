import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `CodedAt` macro-attribute.
///
/// This type can validate`CodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAt: Attribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax
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
        var diagnostics: [(MetaCodableMessage, [FixIt])] = []

        if !declaration.is(VariableDeclSyntax.self) {
            let message = node.diagnostic(
                message: "@\(name) only applicable to variable declarations",
                id: misuseMessageID,
                severity: .error
            )
            diagnostics.append((message, [message.fixItByRemove]))
        }

        if let declaration = declaration.as(VariableDeclSyntax.self),
            declaration.bindings.count > 1
        {
            let message = node.diagnostic(
                message:
                    "@\(name) can't be used with grouped variable declarations",
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

        let notCodedIn =
            UnsupportedCombination<Self, CodedIn>(from: node)?
            .validate(declaration: declaration, in: context) ?? false
        return notCodedIn && diagnostics.isEmpty
    }
}
