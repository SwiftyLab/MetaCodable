/// A variable value containing data whether to perform decoding/encoding.
///
/// The `ConditionalCodingVariable` type forwards `Variable`
/// decoding/encoding, initialization implementations and only
/// decoding/encoding condition are customized.
struct ConditionalCodingVariable<Var: Variable>: DefaultOptionComposedVariable {
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
        let decode: Bool
        /// Whether variable should to be encoded.
        ///
        /// False for variables with `@IgnoreCoding`
        /// and `@IgnoreEncoding` attributes.
        let encode: Bool
    }

    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Var.Initialization

    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: Var
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Creates variable using provided options,
    /// wrapping passed variable.
    ///
    /// The options are used to customize underlying
    /// variable's decoding/encoding implementations.
    ///
    /// - Parameters:
    ///   - base: The underlying variable.
    ///   - options: The options to use.
    ///
    /// - Returns: Newly created variable.
    init(base: Var, options: Options) {
        self.base = base
        self.options = options
    }

    /// Creates variable wrapping passed variable.
    ///
    /// Default options are used that allows direct usage
    /// of underlying variable's decoding/encoding implementations.
    ///
    /// - Parameter base: The underlying variable.
    /// - Returns: Newly created variable.
    init(base: Var) {
        self.init(base: base, options: .init(decode: true, encode: true))
    }

    /// Whether the variable is to be decoded.
    ///
    /// Provides whether underlying variable value is to be decoded,
    /// if provided decode option is set as `true` otherwise `false`.
    var decode: Bool? { options.decode ? base.decode : false }
    /// Whether the variable is to be encoded.
    ///
    /// Provides whether underlying variable value is to be encoded,
    /// if provided encode option is set as `true` otherwise `false`.
    var encode: Bool? { options.encode ? base.encode : false }
}

extension ConditionalCodingVariable: BasicCodingVariable
where Var: BasicCodingVariable {}
