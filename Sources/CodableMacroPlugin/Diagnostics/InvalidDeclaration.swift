@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A diagnostic producer type that can validate syntax type.
///
/// This producer can be used for macro-attributes that require attached syntax
/// should be of specific type.
struct InvalidDeclaration<Attr, Expect>: DiagnosticProducer
where Attr: Attribute, Expect: NamedSyntax {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr
    /// The expected syntax type.
    ///
    /// Error diagnostic is generated
    /// if passed syntax is not of this type.
    let expected: Expect.Type

    /// Creates a syntax type validation instance with provided attribute
    /// and expected type.
    ///
    /// The expected type is used to check syntax and diagnostic is
    /// created at provided attribute if check fails.
    ///
    /// - Parameters:
    ///   - attr: The attribute for which validation performed.
    ///   - expected: The expected syntax type.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr, expect expected: Expect.Type) {
        self.attr = attr
        self.expected = expected
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether passed syntax is of specified syntax type.
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
        guard !syntax.is(expected) else { return false }
        let message = attr.node.diagnostic(
            message: "@\(attr.name) only applicable to \(expected.pluralName)",
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
}

extension Attribute {
    /// Indicates attribute expects the attached syntax of
    /// provided type.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to declarations not of the specified type.
    ///
    /// - Parameter type: The expected declaration type.
    /// - Returns: Declaration validation diagnostic producer.
    func expect<Expect: NamedSyntax>(
        syntax type: Expect.Type
    ) -> InvalidDeclaration<Self, Expect> {
        return .init(self, expect: type)
    }
}

/// A syntax type that has some name associated.
///
/// The associated name is used for diagnostics
/// messages.
protocol NamedSyntax: SyntaxProtocol {
    /// The name associated with this syntax.
    ///
    /// This value is used for diagnostics messages
    /// related to this syntax.
    static var name: String { get }
}

extension NamedSyntax {
    /// The pluralized name of this syntax.
    ///
    /// This is obtained by adding `s` at the end of syntax name.
    static var pluralName: String { "\(name)s" }
}

extension StructDeclSyntax: NamedSyntax {
    /// The name associated with this syntax.
    ///
    /// Indicates declaration is a struct declaration.
    static var name: String { "struct declaration" }
}

extension VariableDeclSyntax: NamedSyntax {
    /// The name associated with this syntax.
    ///
    /// Indicates declaration is a variable declaration.
    static var name: String { "variable declaration" }
}
