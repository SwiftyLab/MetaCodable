import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Describes a macro that provides metadata to `CodableMacro`
/// for individual variable decoding approaches.
///
/// This macro doesn't perform any expansion rather `CodableMacro`
/// uses when performing expansion.
///
/// This macro verifies that it is attached to only variable declarations and
/// necessary metadata provided. If not, then this macro generates diagnostic
/// to remove it.
struct CodableFieldMacro: PeerMacro {
    /// The name of macro that allows `CodingKey`
    /// path customizations
    static var path: String { "CodablePath" }
    /// The name of macro that allows
    /// composition of decoding/encoding
    static var compose: String { "CodableCompose" }

    /// Argument label used to provide a default value
    /// in case of decoding failure.
    static var defaultArgLabel: String { "default" }
    /// Argument label used to provide a helper instance
    /// for decoding/encoding customizations or
    /// custom decoding/encoding implementation.
    static var helperArgLabel: String { "helper" }
    /// Collection of all the argument labels.
    static var argLabels: [String] {
        return [
            Self.defaultArgLabel,
            Self.helperArgLabel,
        ]
    }

    /// Provide metadata to `CodableMacro` for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `CodableMacro`
    /// uses when performing expansion.
    ///
    /// This macro verifies that it is attached to only variable declarations
    /// and necessary metadata provided. If not, then this macro generates
    /// diagnostic to remove it.
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
        let name = node.attributeName
            .as(SimpleTypeIdentifierSyntax.self)!.description

        let (id, msg, severity): (MessageID?, String?, DiagnosticSeverity?) = {
            if !declaration.is(VariableDeclSyntax.self) {
                return (
                    .codableFieldMisuse,
                    "@\(name) only applicable to variable declarations",
                    .error
                )
            } else if name == Self.path,
                node.argument?
                    .as(TupleExprElementListSyntax.self)?.first == nil
            {
                return (
                    .codableFieldUnused,
                    "Unnecessary use of @\(name) without arguments",
                    .warning
                )
            } else {
                return (nil, nil, nil)
            }
        }()

        guard let id, let msg, let severity else { return [] }
        context.diagnose(
            Diagnostic(
                node: Syntax(node),
                message: MetaCodableMessage.diagnostic(
                    message: msg,
                    id: id,
                    severity: severity
                ),
                fixIts: [
                    .init(
                        message: MetaCodableMessage.fixIt(
                            message: "Remove @\(name) attribute",
                            id: id
                        ),
                        changes: [
                            .replace(
                                oldNode: Syntax(node),
                                newNode: Syntax("" as DeclSyntax)
                            )
                        ]
                    )
                ]
            )
        )
        return []
    }
}

/// An extension that manages `CodableFieldMacro`
/// specific message ids.
fileprivate extension MessageID {
    /// Message id for misuse of `CodableFieldMacro` application.
    static var codableFieldMisuse: Self { .messageID("codablefield-misuse") }
    /// Message id for usage of unnecessary `CodableFieldMacro` application.
    ///
    /// The `CodableFieldMacro` can be omitted in such scenario
    /// and the final result will still be the same.
    static var codableFieldUnused: Self { .messageID("codablepath-unused") }
}
