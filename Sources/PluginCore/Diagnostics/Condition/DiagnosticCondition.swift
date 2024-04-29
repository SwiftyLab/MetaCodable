import SwiftSyntax

/// A type that checks if certain syntax is satisfied by some condition.
///
/// This can be used along with `DiagnosticProducer`s to generate
/// different diagnostics based on different conditions.
protocol DiagnosticCondition {
    /// Determines whether provided syntax passes validation.
    ///
    /// This type checks the provided syntax with current data for validation.
    ///
    /// - Parameter syntax: The syntax to validate.
    /// - Returns: Whether syntax passes validation.
    func satisfied(by syntax: some SyntaxProtocol) -> Bool
}

/// A `DiagnosticCondition` that acts as `OR` operation
/// between two `DiagnosticCondition`s.
///
/// This condition is satisfied only if any of the conditions are satisfied.
struct OrDiagnosticCondition<L, R>: DiagnosticCondition
where L: DiagnosticCondition, R: DiagnosticCondition {
    /// The first condition.
    let lhs: L
    /// The second condition.
    let rhs: R

    /// Determines whether provided syntax passes validation.
    ///
    /// This type checks the provided syntax with current data for validation.
    /// This condition is satisfied only if any of the conditions are satisfied.
    ///
    /// - Parameter syntax: The syntax to validate.
    /// - Returns: Whether syntax passes validation.
    func satisfied(by syntax: some SyntaxProtocol) -> Bool {
        return lhs.satisfied(by: syntax) || rhs.satisfied(by: syntax)
    }
}

/// Creates `OrDiagnosticCondition` with provided conditions.
///
/// - Parameters:
///   - lhs: The first condition.
///   - rhs: The second condition.
///
/// - Returns: The resulting condition.
func || <L, R>(lhs: L, rhs: R) -> OrDiagnosticCondition<L, R>
where L: DiagnosticCondition, R: DiagnosticCondition {
    return .init(lhs: lhs, rhs: rhs)
}
