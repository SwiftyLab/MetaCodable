import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate duplicate usage of
/// macro-attribute.
///
/// This producer can be used for macro-attributes that may cause invalid
/// behavior when applied multiple times.
struct DuplicateUsage<Attr: Attribute>: DiagnosticProducer {
    /// The attribute to check duplication for.
    ///
    /// Uses type of attribute to check for duplication.
    let attr: Attr
    /// The severity of produced diagnostic.
    ///
    /// Creates diagnostic with this set severity.
    let severity: DiagnosticSeverity

    /// Creates a macro-attribute duplication validation instance
    /// with provided attribute and severity.
    ///
    /// The provided attribute type is used to check duplication
    /// of same type attribute and diagnostic is created with
    /// provided severity.
    ///
    /// - Parameters:
    ///   - attr: The attribute to check duplication for.
    ///   - severity: The severity of produced diagnostic.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr, severity: DiagnosticSeverity = .error) {
        self.attr = attr
        self.severity = severity
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether macro-attribute of same type is attached multiple
    /// times to the syntax provided, and produces diagnostic with provided
    /// severity if that's the case.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: `True` if syntax fails validation and severity is set
    ///   to error, `false` otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard attr.isDuplicated(in: syntax) else { return false }
        let verb =
            switch severity {
            case .error:
                "can"
            default:
                "should"
            }
        let message = attr.diagnostic(
            message:
                "@\(attr.name) \(verb) only be applied once per declaration",
            id: attr.misuseMessageID,
            severity: severity
        )
        attr.diagnose(message: message, in: context)
        return severity == .error
    }
}

extension Attribute {
    /// Indicates this attribute can't be duplicated.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is duplicated for the same syntax.
    ///
    /// - Returns: Duplication validation diagnostic producer.
    func cantDuplicate() -> DuplicateUsage<Self> {
        return .init(self)
    }

    /// Indicates this attribute shouldn't be duplicated.
    ///
    /// The created diagnostic producer produces warning diagnostic,
    /// if attribute is duplicated for the same syntax.
    ///
    /// - Returns: Duplication validation diagnostic producer.
    func shouldNotDuplicate() -> DuplicateUsage<Self> {
        return .init(self, severity: .warning)
    }
}
