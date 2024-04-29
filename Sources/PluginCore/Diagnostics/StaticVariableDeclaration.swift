import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate passed syntax is not a static
/// variable declaration.
///
/// This producer can be used for macro-attributes that must be attached to
/// non static variable declarations.
struct StaticVariableDeclaration<Attr: PropertyAttribute>: DiagnosticProducer {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr

    /// Creates a static variable declaration validation instance
    /// with provided attribute.
    ///
    /// - Parameter attr: The attribute for which
    ///   validation performed.
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr) {
        self.attr = attr
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether provided syntax is a non static variable declaration,
    /// for static variable declarations error diagnostics
    /// are generated.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: True if syntax fails validation, false otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        // The Macro fails to compile if the .modifiers.contains
        // is directly used in the guard statement.
        let isStatic = syntax.as(VariableDeclSyntax.self)?
            .modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        guard isStatic ?? false else { return false }
        let message = attr.diagnostic(
            message:
                "@\(attr.name) can't be used with static variables declarations",
            id: attr.misuseMessageID,
            severity: .error
        )
        attr.diagnose(message: message, in: context)
        return true
    }
}

extension PropertyAttribute {
    /// Indicates attribute must be attached to non static variable declaration.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to static variable declarations.
    ///
    /// - Returns: Static variable declaration validation diagnostic producer.
    func attachedToNonStaticVariable() -> StaticVariableDeclaration<Self> {
        return .init(self)
    }
}
