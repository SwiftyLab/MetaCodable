import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// An `Attribute` type that can be applied to property declaration.
///
/// This macro doesn't perform any expansion rather `CodableMacro`
/// uses when performing expansion.
///
/// This macro verifies that macro usage condition is met by attached declaration
/// by using the `validate(declaration:in:)` implementation. If not,
/// then this macro generates diagnostic to remove it.
protocol PropertyAttribute: Attribute, PeerMacro {
    /// Whether to allow this attribute to be duplicated.
    ///
    /// If `true`, this attribute can be attached multiple times
    /// on the same variable declaration. If `false`, and
    /// this attribute is applied multiple times, error diagnostics
    /// is generated to remove duplicated attributes.
    var allowDuplication: Bool { get }
    /// The attribute types this attribute can't be combined with.
    ///
    /// If any of the attribute type that is covered in this is applied in the same
    /// declaration as this attribute is attached, then diagnostics generated
    /// to remove this attribute.
    var cantBeCombinedWith: [PropertyAttribute.Type] { get }
}

extension PropertyAttribute {
    /// Whether to allow this attribute to be duplicated.
    ///
    /// If this attribute is applied multiple times, error diagnostics
    /// is generated to remove duplicated attributes.
    var allowDuplication: Bool { false }
    /// The attribute types this attribute can't be combined with.
    ///
    /// This attribute can be combined with any macro-attributes.
    var cantBeCombinedWith: [PropertyAttribute.Type] { [] }

    /// Validates this attribute is used properly with the declaration provided.
    ///
    /// Checks the attribute usage doesn't violate any basic conditions and
    /// produces diagnostics for such violations in the macro expansion
    /// context provided.
    ///
    /// - Parameters:
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The macro expansion context validation performed in.
    ///
    /// - Returns: True if attribute usage satisfies all conditions,
    ///            false otherwise.
    func validate(
        declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        return performBasicValidation(of: declaration, in: context)
    }

    /// Provide metadata to `CodableMacro` for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `CodableMacro`
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached declaration
    /// by using the `validate` implementation provided.
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
        Self(from: node)!.validate(declaration: declaration, in: context)
        return []
    }
}

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

    /// Validates basic rules for this attribute usage with the declaration provided.
    ///
    /// Checks the attribute usage doesn't violate any basic conditions:
    /// * Macro-attribute is attached to variable declaration.
    /// * Macro-attribute follows duplication rule provided by `allowDuplication`.
    /// * Macro-attribute isn't combined with other unsupported attributes
    ///   provided by `cantBeCombinedWith`.
    ///
    /// and produces diagnostics for such violations in the macro expansion
    /// context provided.
    ///
    /// - Parameters:
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The macro expansion context validation performed in.
    ///
    /// - Returns: True if attribute usage satisfies all basic conditions,
    ///            false otherwise.
    func performBasicValidation(
        of declaration: some SyntaxProtocol,
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

        if !allowDuplication, isDuplicated(in: declaration) {
            let message = node.diagnostic(
                message: "@\(name) can only be applied once per declaration",
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

        var result = true
        for type in cantBeCombinedWith {
            let notC = notCombined(with: type, at: declaration, in: context)
            result = result && notC
        }

        return result && diagnostics.contains { $0.0.severity == .error }
    }

    /// Validates the provided declaration doesn't have the passed
    /// attribute type attached.
    ///
    /// Checks the attribute usage doesn't violate any basic conditions:
    /// * Macro-attribute is attached to variable declaration.
    /// * Macro-attribute follows duplication rule provided by `allowDuplication`.
    /// * Macro-attribute isn't combined with other unsupported attributes
    ///   provided by `cantBeCombinedWith`.
    ///
    /// - Parameters:
    ///   - type: The macro-attribute type to check.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The macro expansion context validation performed in.
    ///
    /// - Returns: Whether the passed attribute type is attached
    ///            to the provided declaration.
    private func notCombined(
        with type: PropertyAttribute.Type,
        at declaration: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        var diagnostics: [(MetaCodableMessage, [FixIt])] = []

        guard
            let attr = declaration.attributes(for: type).first
        else { return true }

        let message = node.diagnostic(
            message: "@\(name) can't be used in combination with @\(attr.name)",
            id: misuseMessageID,
            severity: .error
        )

        diagnostics.append((message, [message.fixItByRemove]))
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
