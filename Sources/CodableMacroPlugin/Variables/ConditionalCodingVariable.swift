/// A variable value containing data whether to perform decoding/encoding.
///
/// The `ConditionalCodingVariable` type forwards `Variable`
/// decoding/encoding, initialization implementations and only
/// decoding/encoding condition are customized.
struct ConditionalCodingVariable<Var: Variable>: ComposedVariable, Variable {
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
