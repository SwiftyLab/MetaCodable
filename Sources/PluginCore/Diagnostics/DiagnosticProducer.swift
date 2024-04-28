import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A type producing diagnostics for the passed syntax
/// in the macro expansion context provided.
///
/// This type can produce error/warning diagnostics or both.
protocol DiagnosticProducer {
    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// This type checks the passed syntax doesn't violate any conditions
    /// and produces diagnostics for such violations in the macro expansion
    /// context provided.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: True if syntax fails validation and error diagnostics is
    ///   produced, false otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool
}

extension Attribute {
    /// Produce the provided diagnostic message for the current attribute.
    ///
    /// - Parameters:
    ///   - message: The message for the diagnostic produced.
    ///   - context: The context of macro expansion to produce in.
    func diagnose(
        message: MetaCodableMessage,
        in context: some MacroExpansionContext
    ) {
        let node = Syntax(node)
        let fixIts = [message.fixItByRemove]
        context.diagnose(.init(node: node, message: message, fixIts: fixIts))
    }
}

/// A result builder used to compose `DiagnosticProducer`s.
///
/// This [Result Builder](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders)
/// combines any number of `DiagnosticProducer`s that can produce
/// diagnostics for a common provided declaration.
@resultBuilder
struct DiagnosticsBuilder {
    /// Builds `DiagnosticProducer`s combination from provided data.
    ///
    /// - Parameter producers: The `DiagnosticProducer`s to combine.
    /// - Returns: Combined `DiagnosticProducer`s.
    static func buildBlock(
        _ producers: DiagnosticProducer...
    ) -> [DiagnosticProducer] {
        return producers
    }
}
