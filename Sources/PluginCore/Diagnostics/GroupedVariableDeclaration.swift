import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate passed syntax is not a grouped
/// variable declaration.
///
/// This producer can be used for macro-attributes that must be attached to
/// single variable declarations.
///
/// - Note: This producer also validates passed syntax is of variable
///   declaration type. No need to pass additional diagnostic producer
///   to validate this.
struct GroupedVariableDeclaration<Attr: PropertyAttribute>: DiagnosticProducer {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr
    /// Underlying producer that validates passed syntax is variable
    /// declaration.
    ///
    /// This diagnostic producer is used first to check if passed declaration is
    /// variable declaration. If validation failed, then further validation by
    /// this type is terminated.
    let base: InvalidDeclaration<Attr>

    /// Creates a grouped variable declaration validation instance
    /// with provided attribute.
    ///
    /// Underlying variable declaration validation instance is created
    /// and used first. Post the success of base validation this type
    /// performs validation.
    ///
    /// - Parameter attr: The attribute for which
    ///   validation performed.
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr) {
        self.attr = attr
        self.base = .init(attr, expect: [VariableDeclSyntax.self])
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether provided syntax is a single variable declaration,
    /// for grouped variable and non-variable declarations error diagnostics
    /// is generated.
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
        guard !base.produce(for: syntax, in: context) else { return true }
        guard syntax.as(VariableDeclSyntax.self)!.bindings.count > 1
        else { return false }
        let message = attr.diagnostic(
            message:
                "@\(attr.name) can't be used with grouped variables declaration",
            id: attr.misuseMessageID,
            severity: .error
        )
        attr.diagnose(message: message, in: context)
        return true
    }
}

extension PropertyAttribute {
    /// Indicates attribute must be attached to single variable declaration.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to grouped variable and non-variable
    /// declarations.
    ///
    /// - Returns: Grouped variable declaration validation diagnostic producer.
    func attachedToUngroupedVariable() -> GroupedVariableDeclaration<Self> {
        return .init(self)
    }
}
