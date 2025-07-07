import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate macro-attributes
/// that is used in combination with other macro-attribute types.
///
/// This producer can be used for macro-attributes that may cause invalid
/// behavior when not combined with specific other macro-attributes.
struct CombinedUsage<Attr: Attribute>: DiagnosticProducer {
    /// The attribute to validate.
    ///
    /// Diagnostics is generated at
    /// this attribute.
    let attr: Attr
    /// The combination attribute types.
    ///
    /// The provided attribute is checked
    /// to be used together with any of
    /// these types of attributes.
    let types: [any Attribute.Type]
    /// The severity of produced diagnostic.
    ///
    /// Creates diagnostic with this set severity.
    let severity: DiagnosticSeverity

    /// Creates a macro-attribute combination validation instance
    /// with provided attribute, combination attribute types and severity.
    ///
    /// The provided attribute is checked to be used with the provided
    /// combination attribute types. Diagnostic with specified severity
    /// is created if that's not the case.
    ///
    /// - Parameters:
    ///   - attr: The attribute to validate.
    ///   - types: The combination attribute types.
    ///   - severity: The severity of produced diagnostic.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(
        _ attr: Attr,
        canBeCombinedWith types: [any Attribute.Type],
        severity: DiagnosticSeverity = .error
    ) {
        self.attr = attr
        self.types = types
        self.severity = severity
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether provided macro-attribute is being used in combination
    /// with the provided combination attribute types. Diagnostic is produced
    /// with provided severity if that's not the case.
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
        guard
            types.first(where: { type in
                !type.attributes(attachedTo: syntax).isEmpty
            }) == nil
        else { return false }

        let verb =
            switch severity {
            case .error:
                "must"
            default:
                "should"
            }
        let attrNames: String
        if types.count > 1 {
            attrNames =
                types[0..<(types.count - 1)]
                .map { "@\($0.name)" }
                .joined(separator: ", ") + " or @\(types.last!.name)"
        } else {
            attrNames = "@\(types[0].name)"
        }

        let message = attr.diagnostic(
            message:
                "@\(attr.name) \(verb) be used in combination with \(attrNames)",
            id: attr.misuseMessageID,
            severity: severity
        )
        attr.diagnose(message: message, in: context)
        return severity == .error
    }
}

extension Attribute {
    /// Indicates this macro must be used together with
    /// any of the provided attributes.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute isn't used together with any of the provided
    /// attributes.
    ///
    /// - Parameter types: The combination attribute types.
    /// - Returns: Attribute combination usage validation
    ///   diagnostic producer.
    func mustBeCombined(
        with types: any Attribute.Type, or others: any Attribute.Type...
    ) -> CombinedUsage<Self> {
        var types = [types]
        types.append(contentsOf: others)
        return .init(self, canBeCombinedWith: types)
    }
}
