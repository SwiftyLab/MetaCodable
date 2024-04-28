import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate invalid combination between
/// macro-attribute types.
///
/// This producer can be used for macro-attributes that may cause invalid
/// behavior when combined with specific other macro-attributes.
struct InvalidCombination<Attr, Comb>: DiagnosticProducer
where Attr: Attribute, Comb: Attribute {
    /// The attribute to validate.
    ///
    /// Diagnostics is generated at
    /// this attribute.
    let attr: Attr
    /// The unsupported attribute type.
    ///
    /// The provided attribute is checked
    /// not to be used together with this
    /// type of attribute.
    let type: Comb.Type
    /// The severity of produced diagnostic.
    ///
    /// Creates diagnostic with this set severity.
    let severity: DiagnosticSeverity

    /// Creates a macro-attribute combination validation instance
    /// with provided attribute, unsupported attribute combination
    /// type and severity.
    ///
    /// The provided attribute is checked not used with the provided
    /// unsupported attribute type. Diagnostic with specified severity
    /// is created in such case.
    ///
    /// - Parameters:
    ///   - attr: The attribute to validate.
    ///   - type: The unsupported attribute type.
    ///   - severity: The severity of produced diagnostic.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(
        _ attr: Attr,
        cantBeCombinedWith type: Comb.Type,
        severity: DiagnosticSeverity = .error
    ) {
        self.attr = attr
        self.type = type
        self.severity = severity
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether provided macro-attribute is being used in combination
    /// with the provided unsupported attribute type. Diagnostic is produced
    /// with provided severity if that's the case.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: `True` if syntax fails validation and severity
    ///   is set to error, `false` otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard let uAttr = type.attributes(attachedTo: syntax).first
        else { return false }

        let verb =
            switch severity {
            case .error:
                "can't"
            default:
                "needn't"
            }
        let message = attr.diagnostic(
            message:
                "@\(attr.name) \(verb) be used in combination with @\(uAttr.name)",
            id: attr.misuseMessageID,
            severity: severity
        )
        attr.diagnose(message: message, in: context)
        return severity == .error
    }
}

extension Attribute {
    /// Indicates this macro can't be used together with
    /// the provided attribute.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is used together with the provided attribute.
    ///
    /// - Parameter type: The unsupported attribute type.
    /// - Returns: Invalid attribute combination validation
    ///   diagnostic producer.
    func cantBeCombined<Comb: Attribute>(
        with type: Comb.Type
    ) -> InvalidCombination<Self, Comb> {
        return .init(self, cantBeCombinedWith: type)
    }

    /// Indicates this macro shouldn't be used together with
    /// the provided attribute.
    ///
    /// The created diagnostic producer produces warning diagnostic,
    /// if attribute is used together with the provided attribute.
    ///
    /// - Parameter type: The unsupported attribute type.
    /// - Returns: Invalid attribute combination validation
    ///   diagnostic producer.
    func shouldNotBeCombined<Comb: Attribute>(
        with type: Comb.Type
    ) -> InvalidCombination<Self, Comb> {
        return .init(self, cantBeCombinedWith: type, severity: .warning)
    }
}
