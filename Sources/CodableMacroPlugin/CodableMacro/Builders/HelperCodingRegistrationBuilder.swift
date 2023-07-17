import SwiftSyntax

/// A registration builder updating helper decoding/encoding instance
/// expression data for variable.
///
/// Checks whether any helper decoding/encoding instance provided in attributes attached
/// to variable declaration from the current syntax and updates the registrations variable
/// data accordingly.
struct HelperCodingRegistrationBuilder: OptionalRegistrationBuilder {
    /// The basic variable data that input registration can have.
    typealias Input = BasicVariable
    /// The optional variable data with helper expression
    /// that output registration may have.
    typealias Optional = HelperCodedVariable

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with helper expression data that will be used
    /// for decoding/encoding, if provided.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with helper expression data.
    func build(with input: Registration<Input>) -> Registration<Optional>? {
        guard
            case let attributes = input.context.attributes,
            let attr = attributes.first(where: { $0 is HelperCodingAttribute }),
            let args = attr.node.argument?.as(TupleExprElementListSyntax.self),
            let helperArg = args.first(where: { $0.label?.text == "helper" }),
            case let expr = helperArg.expression
        else { return nil }
        return input.updating(with: input.variable.with(helper: expr))
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

/// A specialized `Attribute` type that supports providing helper instance expression.
///
/// `HelperCodingRegistrationBuilder` uses attributes of this type
/// to extract helper expressions and update registration data.
fileprivate protocol HelperCodingAttribute: Attribute {}
extension CodedAt: HelperCodingAttribute {}
extension CodedIn: HelperCodingAttribute {}
