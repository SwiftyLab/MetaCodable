import SwiftSyntax

/// A registration builder updating helper expression data that
/// will be used for decoding/encoding for variable.
///
/// New registration is updated with helper expression data that will be
/// used for decoding/encoding, if provided.
struct HelperCodingRegistrationBuilder<Input>: RegistrationBuilder
    where Input: BasicCodingVariable
{
    /// The optional variable data with helper expression
    /// that output registration will have.
    typealias Output = AnyVariable<Input.Initialization>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with helper expression data that will be
    /// used for decoding/encoding, if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with helper expression data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        guard let attr = CodedBy(from: input.context.declaration)
        else { return input.updating(with: input.variable.any) }
        let newVar = input.variable.with(helper: attr.expr)
        return input.adding(attribute: attr).updating(with: newVar.any)
    }
}

private extension BasicCodingVariable {
    /// Update variable data with the helper instance expression provided.
    ///
    /// `HelperCodedVariable` is created with this variable as base
    /// and helper expression provided.
    ///
    /// - Parameter expr: The helper expression to add.
    /// - Returns: Created variable data with helper expression.
    func with(helper expr: ExprSyntax) -> HelperCodedVariable<Self> {
        return .init(base: self, options: .init(expr: expr))
    }
}
