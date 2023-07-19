import SwiftSyntax

extension Default: RegistrationBuilder {
    /// The variable data with default expression that output registration will have.
    typealias Output = DefaultValueVariable<AnyVariable>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with default expression data that will be used
    /// for decoding failure and member-wise initializer, if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with default expression data.
    func build(with input: Registration<AnyVariable>) -> Registration<Output> {
        let expr = node.argument!
            .as(TupleExprElementListSyntax.self)!.first!.expression
        return input.updating(with: input.variable.with(default: expr))
    }
}

fileprivate extension Variable {
    /// Update variable data with the default value expression provided.
    ///
    /// `DefaultValueVariable` is created with this variable as base
    /// and default expression provided.
    ///
    /// - Parameter expr: The default expression to add.
    /// - Returns: Created variable data with default expression.
    func with(default expr: ExprSyntax) -> DefaultValueVariable<Self> {
        return .init(base: self, options: .init(expr: expr))
    }
}
