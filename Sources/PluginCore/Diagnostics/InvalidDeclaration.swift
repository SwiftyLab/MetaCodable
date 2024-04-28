import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate syntax type.
///
/// This producer can be used for macro-attributes that require attached syntax
/// should be of specific type.
struct InvalidDeclaration<Attr>: DiagnosticProducer where Attr: Attribute {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr
    /// The expected syntax types.
    ///
    /// Error diagnostic is generated if passed
    /// syntax is not of any of these types.
    let expected: [any SyntaxProtocol.Type]

    /// Creates a syntax type validation instance with provided attribute
    /// and expected types.
    ///
    /// The expected types are used to check syntax and diagnostic is
    /// created at provided attribute if check fails.
    ///
    /// - Parameters:
    ///   - attr: The attribute for which validation performed.
    ///   - expected: The expected syntax types.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr, expect expected: [any SyntaxProtocol.Type]) {
        self.attr = attr
        self.expected = expected
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether passed syntax is of specified syntax types.
    /// Diagnostic is produced if that's not the case.
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
        guard !expected.contains(where: { syntax.is($0) }) else { return false }
        let names = expected.map { name(for: $0) }.joined(separator: " or ")
        let message = attr.diagnostic(
            message: "@\(attr.name) only applicable to \(names) declarations",
            id: attr.misuseMessageID,
            severity: .error
        )
        context.diagnose(
            .init(
                node: Syntax(attr.node),
                message: message,
                fixIts: [message.fixItByRemove]
            )
        )
        return true
    }

    /// The name associated with provided syntax type.
    ///
    /// Indicates declaration name.
    ///
    /// - Parameter syntax: The syntax type
    /// - Returns: The name of syntax type.
    func name(for syntax: SyntaxProtocol.Type) -> String {
        func kebabCased(_ str: String) -> String {
            return CodingKeyTransformer(strategy: .kebab－case)
                .transform(key: str)
        }
        let name = "\(syntax)"
        let suffix = "DeclSyntax"
        guard name.hasSuffix(suffix) else { return kebabCased(name) }
        return kebabCased(String(name.dropLast(suffix.count)))
    }
}

extension Attribute {
    /// Indicates attribute expects the attached syntax of
    /// provided types.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to declarations not of the specified types.
    ///
    /// - Parameter types: The expected declaration types.
    /// - Returns: Declaration validation diagnostic producer.
    func expect(
        syntaxes types: SyntaxProtocol.Type...
    ) -> InvalidDeclaration<Self> {
        return .init(self, expect: types)
    }
    /// Indicates attribute expects the attached syntax of
    /// provided types.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to declarations not of the specified types.
    ///
    /// - Parameter types: The expected declaration types.
    /// - Returns: Declaration validation diagnostic producer.
    func expect(
        syntaxes types: [SyntaxProtocol.Type]
    ) -> InvalidDeclaration<Self> {
        return .init(self, expect: types)
    }
}
