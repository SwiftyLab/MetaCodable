import SwiftSyntax
import SwiftSyntaxMacros

/// A diagnostic producer type that can produce different diagnostics
/// based on condition.
///
/// This producer first checks provided syntax against condition and
/// produces diagnostics based on condition result.
struct ConditionalDiagnosticProducer<Condition, Producer, Fallback>:
    DiagnosticProducer
where
    Condition: DiagnosticCondition, Producer: DiagnosticProducer,
    Fallback: DiagnosticProducer
{
    /// The condition to check.
    ///
    /// Used to check syntax first and
    /// produce diagnostics based on result.
    let condition: Condition
    /// The primary diagnostic producer.
    ///
    /// Used when condition satisfied.
    let producer: Producer
    /// The fallback diagnostic producer.
    ///
    /// Used when condition validation failed.
    let fallback: Fallback

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks provided syntax against `condition` and produces
    /// diagnostics based on condition result.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: `True` if syntax fails validation, `false` otherwise.
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard condition.satisfied(by: syntax) else {
            return fallback.produce(for: syntax, in: context)
        }
        return producer.produce(for: syntax, in: context)
    }
}

extension Attribute {
    /// Indicates different diagnostics needs to be produced based on condition.
    ///
    /// Produces primary diagnostics if condition satisfied, otherwise fallback
    /// diagnostics produced.
    ///
    /// - Parameters:
    ///   - condition: The condition to check.
    ///   - producer: The primary diagnostic producer.
    ///   - fallback: The fallback diagnostic producer.
    ///
    /// - Returns: The conditional diagnostic producer.
    func `if`<Condition, Producer, Fallback>(
        _ condition: Condition, _ producer: Producer, else fallback: Fallback
    ) -> ConditionalDiagnosticProducer<Condition, Producer, Fallback>
    where
        Condition: DiagnosticCondition, Producer: DiagnosticProducer,
        Fallback: DiagnosticProducer
    {
        return .init(
            condition: condition, producer: producer, fallback: fallback
        )
    }
}
