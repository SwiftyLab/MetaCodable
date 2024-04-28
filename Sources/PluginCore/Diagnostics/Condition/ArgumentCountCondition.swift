import SwiftSyntax

/// Validates provided attribute has expected argument count.
///
/// Checks provided attribute has `expected` number of argument(s).
struct ArgumentCountCondition<Attr>: DiagnosticCondition where Attr: Attribute {
    /// The attribute for which
    /// validation performed.
    ///
    /// The argument count of
    /// this attribute is compared.
    let attr: Attr
    /// The expected argument count.
    ///
    /// Syntax satisfied if the argument
    /// count matches this value.
    let expected: Int

    /// Determines whether provided syntax passes validation.
    ///
    /// This type checks whether passed attribute argument(s) is of specified
    /// `expected` value.
    ///
    /// - Parameter syntax: The syntax to validate.
    /// - Returns: Whether syntax passes validation.
    func satisfied(by syntax: some SyntaxProtocol) -> Bool {
        return expected == attr.node.arguments?
            .as(LabeledExprListSyntax.self)?.count ?? 0
    }
}

extension Attribute {
    /// Indicates attribute expects the argument count to match
    /// provided count.
    ///
    /// The created `ArgumentCountCondition` checks if
    /// attribute argument(s) count matches the specified count.
    ///
    /// - Parameter count: The expected argument count.
    /// - Returns: Declaration validation diagnostic producer.
    func has(arguments count: Int) -> ArgumentCountCondition<Self> {
        return .init(attr: self, expected: count)
    }
}
