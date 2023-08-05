/// A variable value containing data whether explicit decoding/encoding
/// is asked.
///
/// The `KeyedVariable` type forwards `Variable`
/// decoding/encoding, initialization implementations and only
/// decoding/encoding condition are customized.
struct KeyedVariable<Var: Variable>: ComposedVariable {
    /// The customization options for `KeyedVariable`.
    ///
    /// `KeyedVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// Whether variable needs to be decoded/encoded.
        ///
        /// `True` if `CodedAt` or `CodedIn` macro
        /// is attached to variable.
        let code: Bool
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

    /// Whether the variable is to be decoded.
    ///
    /// Provides whether underlying variable value is to be decoded,
    /// if provided code option is set as `false` otherwise `true`.
    var decode: Bool? { options.code ? true : base.decode }
    /// Whether the variable is to be encoded.
    ///
    /// Provides whether underlying variable value is to be encoded,
    /// if provided code option is set as `false` otherwise `true`.
    var encode: Bool? { options.code ? true : base.encode }
}

extension KeyedVariable: BasicCodingVariable
where Var: BasicCodingVariable {}
