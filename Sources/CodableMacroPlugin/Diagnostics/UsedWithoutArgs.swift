import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate whether macro-attribute
/// is used without any provided argument(s).
///
/// This producer can be used for macro-attributes that are unnecessary
/// to be used without any argument(s).
struct UsedWithoutArgs<Attr: Attribute>: DiagnosticProducer {
    /// The attribute to check argument(s) for.
    ///
    /// Diagnostic is created at this attribute
    /// if check fails.
    let attr: Attr

    /// Creates an attribute argument(s) validation instance
    /// with provided attribute.
    ///
    /// Checks whether provided macro-attribute is used
    /// without any provided argument(s), and produces
    /// warning diagnostic if that's the case.
    ///
    /// - Parameter attr: The attribute for which
    ///                   validation performed.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr) {
        self.attr = attr
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether macro-attribute is used without any provided argument(s),
    /// and produces warning diagnostic if that's the case.
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
        guard
            attr.node.arguments?
                .as(LabeledExprListSyntax.self)?.first == nil
        else { return false }

        let message = attr.node.diagnostic(
            message: "Unnecessary use of @\(attr.name) without argument(s)",
            id: attr.unusedMessageID,
            severity: .warning
        )
        context.diagnose(attr: attr, message: message)
        return false
    }
}

extension Attribute {
    /// Indicates this attribute should not be used without argument(s).
    ///
    /// The created diagnostic producer produces warning diagnostic,
    /// if attribute is used without any argument(s).
    ///
    /// - Returns: Argument(s) validation diagnostic producer.
    func shouldNotBeUsedWithoutArgs() -> UsedWithoutArgs<Self> {
        return .init(self)
    }
}
