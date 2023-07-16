import SwiftSyntax

/// A registration builder updating default expression data for variable.
///
/// Checks whether any default expression provided in attributes attached to variable declaration
/// from the current syntax and updates the registrations variable data accordingly.
struct DefaultCodingRegistrationBuilder<Input>: OptionalRegistrationBuilder
where Input: Variable {
    /// The optional variable data with default expression
    /// that output registration may have.
    typealias Optional = DefaultValueVariable<Input>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with default expression data that will be used
    /// for decoding failure and member-wise initializer, if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with default expression data.
    func build(with input: Registration<Input>) -> Registration<Optional>? {
        guard
            case let attrs = input.context.attributes,
            let attr = attrs.first(where: { $0 is DefaultCodingAttribute }),
            let args = attr.node.argument?.as(TupleExprElementListSyntax.self),
            let helperArg = args.first(where: { $0.label?.text == "default" }),
            case let expr = helperArg.expression
        else { return nil }
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
        return .init(base: self, option: .init(expr: expr))
    }
}

/// A specialized `Attribute` type that supports providing default expression.
///
/// `DefaultCodingRegistrationBuilder` uses attributes of this type
/// to extract default expressions and update registration data.
fileprivate protocol DefaultCodingAttribute: Attribute {}
extension CodedAt: DefaultCodingAttribute {}
extension CodedIn: DefaultCodingAttribute {}
