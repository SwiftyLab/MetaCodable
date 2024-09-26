import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntaxMacros

/// The compiler plugin that exposes all the macro type defined.
///
/// New macro types should be added to `providingMacros`
/// array.
@main
struct TestingMacroPlugin: CompilerPlugin {
    /// All the macros provided by this macro plugin.
    ///
    /// New macro types should be added here.
    let providingMacros: [Macro.Type] = [
        Test.self,
        Tag.self,
        Expect.self,
        ExpectThrows.self,
        RequireOptional.self,
    ]
}

struct TestingMacroMessage: DiagnosticMessage {
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
    var diagnosticID: MessageID {
        return .init(domain: "com.SwiftyLab.Testing", id: "noimpl")
    }

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
}
