import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can validate passed syntax is not an
/// uninitialized variable declaration.
///
/// This producer can be used for macro-attributes that must be attached to
/// initialized variable declarations.
///
/// - Note: This producer also validates passed syntax is of variable
///   declaration type. No need to pass additional diagnostic producer
///   to validate this.
struct UninitializedVariableDecl<Attr: PropertyAttribute>: DiagnosticProducer {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr
    /// Underlying producer that validates passed syntax
    /// is variable declaration.
    ///
    /// This diagnostic producer is used first to check
    /// if passed declaration is variable declaration.
    /// If validation failed, then further validation by
    /// this type is terminated.
    let base: InvalidDeclaration<Attr>

    /// Creates an uninitialized variable declaration validation instance
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
    /// Checks whether each variable provided syntax is an initialized
    /// declaration, for uninitialized variables and non-variable declarations
    /// error diagnostics is generated.
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

        var result = false
        let decl = syntax.as(VariableDeclSyntax.self)!
        for binding in decl.bindings {
            switch binding.accessorBlock?.accessors {
            case .getter:
                continue
            case .accessors(let accessors):
                let computed = accessors.contains { decl in
                    decl.accessorSpecifier.tokenKind == .keyword(.get)
                }
                // TODO: Re-evaluate when init accessor is introduced
                // https://github.com/apple/swift-evolution/blob/main/proposals/0400-init-accessors.md
                // && !accessors.contains { decl in
                //     decl.accessorKind.tokenKind == .keyword(.`init`)
                // }
                guard computed else { fallthrough }
                continue
            default:
                let type = binding.typeAnnotation?.type
                let isOptional = type?.isOptionalTypeSyntax ?? false
                let mutable = decl.bindingSpecifier.tokenKind == .keyword(.var)
                guard
                    binding.initializer == nil && !(isOptional && mutable)
                else { continue }
            }

            var msg = """
                @\(attr.name) can't be used with uninitialized non-optional variable
                """
            if let varName = binding.pattern.as(IdentifierPatternSyntax.self)?
                .identifier.text
            {
                msg.append(" \(varName)")
            }
            let message = attr.diagnostic(
                message: msg,
                id: attr.misuseMessageID,
                severity: .error
            )
            attr.diagnose(message: message, in: context)
            result = true
        }
        return result
    }
}

extension PropertyAttribute {
    /// Indicates attribute must be attached to initialized variable
    /// declaration.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute is attached to uninitialized variable and non-variable
    /// declarations.
    ///
    /// - Returns: Uninitialized variable declaration validation diagnostic
    ///   producer.
    func attachedToInitializedVariable() -> UninitializedVariableDecl<Self> {
        return .init(self)
    }
}
