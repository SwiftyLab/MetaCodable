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
    fileprivate init(
        macro: AttributeSyntax,
        message: String,
        messageID: MessageID,
        severity: DiagnosticSeverity
    ) {
        self.macro = macro
        self.message = message
        diagnosticID = messageID
        self.severity = severity
    }

    /// Generate `FixIt` for removing
    /// the provided `macro` attribute.
    var fixItByRemove: FixIt {
        let name = macro.attributeName
            .as(IdentifierTypeSyntax.self)!.description
        return .init(
            message: macro.fixIt(
                message: "Remove @\(name) attribute",
                id: fixItID
            ),
            changes: [
                .replace(
                    oldNode: Syntax(macro),
                    newNode: Syntax("" as DeclSyntax)
                ),
            ]
        )
    }
}

/// An extension that manages diagnostic
/// and fixes messages related to attributes.
extension AttributeSyntax {
    /// Creates a new diagnostic message instance
    /// with provided message, id and severity.
    ///
    /// - Parameters:
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with diagnostic.
    ///   - severity: The severity of diagnostic.
    ///
    /// - Returns: The newly created diagnostic message instance.
    func diagnostic(
        message: String,
        id: MessageID,
        severity: DiagnosticSeverity
    ) -> MetaCodableMessage {
        return .init(
            macro: self,
            message: message,
            messageID: id,
            severity: severity
        )
    }

    /// Creates a new fixit/quick-fix message instance
    /// with provided message and id.
    ///
    /// - Parameters:
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with the fix suggested.
    ///
    /// - Returns: The newly created fixit/quick-fix message instance.
    func fixIt(message: String, id: MessageID) -> MetaCodableMessage {
        return .init(
            macro: self,
            message: message,
            messageID: id,
            severity: .warning
        )
    }
}

/// An extension that manages
/// module specific message ids.
extension MessageID {
    /// Creates a new message id in current package domain.
    ///
    /// - Parameters id: The message id.
    /// - Returns: Created message id.
    static func messageID(_ id: String) -> Self {
        return .init(
            domain: "com.SwiftyLab.MetaCodable",
            id: id
        )
    }
}
