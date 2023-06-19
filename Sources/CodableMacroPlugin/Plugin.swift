import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntaxMacros

/// The compiler plugin that exposes all the macro type defined.
///
/// New macro types should be added to `providingMacros`
/// array.
@main
struct MetaCodablePlugin: CompilerPlugin {
    /// All the macros provided by this macro plugin.
    ///
    /// New macro types should be added here.
    let providingMacros: [Macro.Type] = [
        CodableFieldMacro.self,
        CodableMacro.self,
    ]
}

/// A message type used as `DiagnosticMessage` and `FixItMessage`
/// for this macro plugin.
///
/// This type is used to display diagnostic messages for warnings
/// and errors due to the usage of macros from this package
/// and to provide quick fixes to these.
struct MetaCodableMessage: Error, DiagnosticMessage, FixItMessage {
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
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with message.
    ///   - severity: The severity of diagnostic.
    ///
    /// - Returns: The newly created message instance.
    private init(
        message: String,
        messageID: MessageID,
        severity: DiagnosticSeverity
    ) {
        self.message = message
        self.diagnosticID = messageID
        self.severity = severity
    }

    /// Creates a new diagnostic message instance
    /// with provided message, id and severity.
    ///
    /// - Parameters:
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with diagnostic.
    ///   - severity: The severity of diagnostic.
    ///
    /// - Returns: The newly created diagnostic message instance.
    static func diagnostic(
        message: String,
        id: MessageID,
        severity: DiagnosticSeverity
    ) -> Self {
        return .init(
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
    static func fixIt(message: String, id: MessageID) -> Self {
        return .init(
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
    static func messageID(_ id: String) -> Self {
        return .init(
            domain: "com.SwiftyLab.MetaCodable",
            id: id
        )
    }
}
