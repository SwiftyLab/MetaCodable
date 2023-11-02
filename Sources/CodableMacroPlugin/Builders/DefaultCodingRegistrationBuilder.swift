@_implementationOnly import SwiftSyntax

/// A registration builder updating default value expression data that
/// will be used for decoding failure and memberwise initializer(s)
/// data for variable.
///
/// New registration is updated with default expression data that will be
/// used for decoding failure and memberwise initializer(s), if provided.
struct DefaultCodingRegistrationBuilder<Input: Variable>: RegistrationBuilder
where Input.Initialization == RequiredInitialization {
    /// The variable data with default expression
    /// that output registration will have.
    typealias Output = AnyVariable<AnyRequiredVariableInitialization>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with default expression data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        guard let attr = Default(from: input.context.declaration)
        else { return input.updating(with: input.variable.any) }
        let newVar = input.variable.with(default: attr.expr)
        return input.adding(attribute: attr).updating(with: newVar.any)
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
