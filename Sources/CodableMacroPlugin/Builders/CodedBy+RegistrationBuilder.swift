import SwiftSyntax

extension CodedBy: RegistrationBuilder {
    /// The basic variable data that input registration can have.
    typealias Input = BasicVariable
    /// The optional variable data with helper expression
    /// that output registration will have.
    typealias Output = HelperCodedVariable

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with helper expression data that will be
    /// used for decoding/encoding, if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with helper expression data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let expr = node.argument!
            .as(TupleExprElementListSyntax.self)!.first!.expression
        let newVar = input.variable.with(helper: expr)
        return input.adding(attribute: self).updating(with: newVar)
    }
}

fileprivate extension BasicVariable {
    /// Update variable data with the helper instance expression provided.
    ///
    /// `HelperCodedVariable` is created with this variable as base
    /// and helper expression provided.
    ///
    /// - Parameter expr: The helper expression to add.
    /// - Returns: Created variable data with helper expression.
    func with(helper expr: ExprSyntax) -> HelperCodedVariable {
        return .init(base: self, options: .init(expr: expr))
    }
}
