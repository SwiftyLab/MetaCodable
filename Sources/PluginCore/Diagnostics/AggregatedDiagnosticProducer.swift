import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can aggregate a group of diagnostic
/// producers.
///
/// This producer can be used to compose complex diagnostic producer that
/// performs multiple validations and produces variety of diagnostics using
/// aggregated diagnostic producers.
struct AggregatedDiagnosticProducer: DiagnosticProducer {
    /// The underlying diagnostic producers to use.
    ///
    /// These diagnostic producers are used to
    /// perform validation and produce diagnostics.
    let producers: [DiagnosticProducer]

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Forwards provided syntax and macro expansion context to each
    /// producer to perform validation and produce diagnostics.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: True if syntax fails validation and error diagnostics is
    ///   produced by any of the producers, false otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        return producers.reduce(false) { partialResult, producer in
            /// `producer.produce(for:in:)` should be invoked first to avoid
            /// diagnostic evaluation termination due to short-circuit
            /// evaluation.
            return producer.produce(for: syntax, in: context) || partialResult
        }
    }
}

extension AggregatedDiagnosticProducer {
    /// Creates an aggregated diagnostic producer form the provided producers.
    ///
    /// This convenience initializer makes it easier to create aggregated
    /// diagnostic producer by using result builder.
    ///
    /// - Parameter builder: The action that creates diagnostic producers.
    /// - Returns: Newly created diagnostic producer.
    init(@DiagnosticsBuilder builder: () -> [DiagnosticProducer]) {
        self.init(producers: builder())
    }
}
