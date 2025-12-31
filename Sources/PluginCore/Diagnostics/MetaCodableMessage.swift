import SwiftDiagnostics
import SwiftSyntax

/// A message type used as `DiagnosticMessage` and `FixItMessage`
/// for this macro plugin.
///
/// This type is used to display diagnostic messages for warnings
/// and errors due to the usage of macros from this package
/// and to provide quick fixes to these.
struct MetaCodableMessage: Error, DiagnosticMessage, FixItMessage {
    /// The macro attribute this message
    /// is generated for and showed at.
    let macro: AttributeSyntax
    /// The diagnostic message or quick-fix message
    /// that should be displayed in the client.
    let message: String
    /// An identifier that identifies
    /// a diagnostic message's type.
    ///
    /// Fundamentally different diagnostics
    /// should have different `diagnosticID`s
    /// so that clients may filter/prioritize/highlight/...
    /// certain diagnostics. Two diagnostics with
    /// the same ID don’t need to necessarily have
    /// the exact same wording. Eg. it’s possible that
    /// the message contains more context when available.
    let diagnosticID: MessageID
    /// The severity (warning/error etc.) of
    /// the diagnostic message.
    ///
    /// This is not used when this type is used
    /// as quick-fix message.
    let severity: DiagnosticSeverity

    /// Same as `diagnosticID`.
    ///
    /// Used for fixits/quick-fixes,
    /// and ignored for diagnostics.
    var fixItID: MessageID { diagnosticID }

    /// Generate `FixIt` for removing
    /// the provided `macro` attribute.
    var fixItByRemove: FixIt {
        let name = macro.attributeName
            .as(IdentifierTypeSyntax.self)!.name.text
        return .init(
            message: Self.fixIt(
                macro: macro,
                message: "Remove @\(name) attribute",
                id: fixItID
            ),
            changes: [
                .replace(
                    oldNode: Syntax(macro),
                    newNode: Syntax([] as AttributeListSyntax)
                )
            ]
        )
    }

    /// Creates a new message instance
    /// with provided message, id and severity.
    ///
    /// Use `diagnostic(message:id:)`
    /// or `fixIt(message:id:)` to create
    /// diagnostic or quick-fix messages respectively
    ///
    /// - Parameters:
    ///   - macro: The macro attribute message shown at.
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with message.
    ///   - severity: The severity of diagnostic.
    ///
    /// - Returns: The newly created message instance.
    init(
        macro: AttributeSyntax,
        message: String,
        messageID: MessageID,
        severity: DiagnosticSeverity
    ) {
        self.macro = macro
        self.message = message
        self.diagnosticID = messageID
        self.severity = severity
    }

    /// Creates a new fixit/quick-fix message instance
    /// with provided message and id.
    ///
    /// - Parameters:
    ///   - macro: The macro attribute message is shown at.
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with the fix suggested.
    ///
    /// - Returns: The newly created fixit/quick-fix message instance.
    static func fixIt(
        macro: AttributeSyntax,
        message: String, id: MessageID
    ) -> MetaCodableMessage {
        .init(
            macro: macro, message: message, messageID: id, severity: .warning
        )
    }
}

/// A diagnostic message for macro expansion errors in MetaCodable.
///
/// This struct represents an error or warning that occurs during macro expansion,
/// providing contextual information about what went wrong and where it occurred.
/// It conforms to both `Error` and `DiagnosticMessage` to integrate with Swift's
/// macro diagnostic system.
///
/// - Parameters:
///   - Attr: The attribute type that caused the error, which must conform to `Attribute`
struct MetaCodableMacroExpansionErrorMessage<Attr>: Error, DiagnosticMessage
where Attr: Attribute {
    /// The human-readable error message describing what went wrong
    let message: String
    /// The severity level of the diagnostic (error, warning, note, etc.)
    let severity: DiagnosticSeverity

    /// The unique diagnostic identifier based on the attribute type
    var diagnosticID: MessageID {
        Attr.messageID(Attr.misuseId)
    }

    /// Creates a new macro expansion error message.
    ///
    /// - Parameters:
    ///   - message: A descriptive error message explaining the issue
    ///   - severity: The diagnostic severity level (defaults to `.error`)
    init(_ message: String, severity: DiagnosticSeverity = .error) {
        self.severity = severity
        self.message = message
    }
}

#if !canImport(SwiftSyntax600)
extension MetaCodableMessage: @unchecked Sendable {}
extension MetaCodableMacroExpansionErrorMessage: @unchecked Sendable {}
#endif
