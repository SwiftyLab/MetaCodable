import SwiftSyntax
import SwiftSyntaxMacros

/// A variable value containing data whether to perform decoding/encoding.
///
/// The `ConditionalCodingVariable` type forwards `Variable`
/// decoding/encoding, initialization implementations and only
/// decoding/encoding condition are customized.
struct ConditionalCodingVariable<Var>: ComposedVariable, Variable
where Var: ConditionalVariable, Var.Generated: ConditionalVariableSyntax {
    /// The customization options for `ConditionalCodingVariable`.
    ///
    /// `ConditionalCodingVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// Whether variable needs to be decoded.
        ///
        /// `True` for non-initialized stored variables.
        /// `False` for variables with `@IgnoreCoding`
        /// and `@IgnoreDecoding` attributes.
        let decode: Bool?
        /// Whether variable should to be encoded.
        ///
        /// False for variables with `@IgnoreCoding`
        /// and `@IgnoreEncoding` attributes.
        let encode: Bool?
        /// The condition expression based on which encoding is decided.
        ///
        /// This expression accepts arguments from this variable and resolves
        /// to either `true` or `false` based on which encoding is ignored.
        let encodingConditionExpr: ExprSyntax?
    }

    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: Var
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// If any encoding condition expression is provided then based on the
    /// result of the expression encoding is performed by generated syntax.
    /// Otherwise, provides code syntax for encoding of the underlying
    /// variable value.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: Var.CodingLocation
    ) -> Var.Generated {
        let syntax = base.encoding(in: context, to: location)
        guard
            let conditionExpr = options.encodingConditionExpr
        else { return syntax }
        let args = self.conditionArguments
        let returnList = TupleTypeElementListSyntax {
            for _ in args {
                TupleTypeElementSyntax(type: "_" as TypeSyntax)
            }
        }
        let expr: ExprSyntax =
            "!{ () -> (\(returnList)) -> Bool in \(conditionExpr) }()(\(args))"
        return syntax.adding(condition: [.init(expression: expr)])
    }
}

extension ConditionalCodingVariable: ConditionalVariable
where Wrapped: ConditionalVariable {
    /// Whether the variable is to be decoded.
    ///
    /// Provides whether underlying variable value is to be decoded,
    /// if provided decode option is set as `true` otherwise `false`.
    var decode: Bool? { (options.decode ?? true) ? base.decode : false }
    /// Whether the variable is to be encoded.
    ///
    /// Provides whether underlying variable value is to be encoded,
    /// if provided encode option is set as `true` otherwise `false`.
    var encode: Bool? { (options.encode ?? true) ? base.encode : false }
}

extension ConditionalCodingVariable: PropertyVariable
where Var: PropertyVariable {
    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Decodable` conformance, if provided decode
    /// option is set as `true` otherwise `false`.
    var requireDecodable: Bool? {
        return (options.decode ?? true) ? base.requireDecodable : false
    }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Encodable` conformance, if provided encode
    /// option is set as `true` otherwise `false`.
    var requireEncodable: Bool? {
        return (options.encode ?? true) ? base.requireEncodable : false
    }
}

extension ConditionalCodingVariable: InitializableVariable
where Var: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Var.Initialization
}

extension ConditionalCodingVariable: NamedVariable where Var: NamedVariable {}
extension ConditionalCodingVariable: ValuedVariable where Var: ValuedVariable {}

extension ConditionalCodingVariable: DefaultPropertyVariable
where Var: DefaultPropertyVariable {}

extension ConditionalCodingVariable: AssociatedVariable
where Var: AssociatedVariable {}
extension ConditionalCodingVariable: EnumCaseVariable
where Var: EnumCaseVariable {}
