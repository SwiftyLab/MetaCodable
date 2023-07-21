import SwiftSyntax

extension Default: RegistrationBuilder {
    /// The any variable data with required initialization that input registration can have.
    typealias Input = AnyVariable<RequiredInitialization>
    /// The variable data with default expression that output registration will have.
    typealias Output = DefaultValueVariable<Input>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with default expression data that will be used
    /// for decoding failure and member-wise initializer(s), if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with default expression data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let expr = node.argument!
            .as(TupleExprElementListSyntax.self)!.first!.expression
        return input.updating(with: input.variable.with(default: expr))
    }
}

fileprivate extension Variable where Initialization == RequiredInitialization {
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
