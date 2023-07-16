import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `CodedIn` macro-attribute.
///
/// This type can validate`CodedIn` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedIn: Attribute {
    /// Represents whether initialized
    /// without attribute syntax.
    let inDefaultMode: Bool
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
        self.inDefaultMode = false
    }

    /// Creates a new instance with default node.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init() {
        self.node = .init("\(raw: Self.name)")
        self.inDefaultMode = true
    }

    /// Validates this attribute is used properly with the declaration provided.
    ///
    /// The following conditions are checked for validations:
    /// * Attached declaration is a variable declaration.
    /// * This attribute isn't used combined with `CodedAt` attribute.
    ///
    /// Warning is generated if this attribute is used without any arguments,
    /// but validation is success for this scenario.
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

        if node.argument?.as(TupleExprElementListSyntax.self)?.first == nil {
            let message = node.diagnostic(
                message: "Unnecessary use of @\(name) without arguments",
                id: unusedMessageID,
                severity: .warning
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

        let notCodedAt =
            UnsupportedCombination<Self, CodedAt>(from: node)?
            .validate(declaration: declaration, in: context) ?? true
        return notCodedAt && diagnostics.contains { $0.0.severity == .error }
    }
}
