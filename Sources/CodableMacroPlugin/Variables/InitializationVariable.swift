import SwiftSyntax
import SwiftSyntaxMacros

/// A variable value containing initialization data.
///
/// The `InitializationVariable` type forwards `Variable`
/// encoding implementations, while customizing decoding and initialization
/// implementations.
struct InitializationVariable<Wrapped: Variable>: ComposedVariable
where Wrapped.Initialization: RequiredVariableInitialization {
    /// The customization options for `InitializationVariable`.
    ///
    /// `InitializationVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// Whether variable can be initialized.
        ///
        /// True for non-initialized stored variables,
        /// initialized mutable variables. False for
        /// computed and initialized immutable variables.
        let `init`: Bool
        /// Whether variable has been initialized.
        ///
        /// True if variable has any initializing expression,
        /// false otherwise.
        let initialized: Bool
    }

    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: Wrapped
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Whether the variable is to be decoded.
    ///
    /// `false` if variable can't be initialized, otherwise depends on
    /// whether underlying variable is to be decoded.
    var decode: Bool? { options.`init` ? base.decode : false }
    /// Whether the variable is to be encoded.
    ///
    /// Depends on whether variable is initializable if underlying variable doesn't
    /// specify explicit encoding. Otherwise depends on whether underlying variable
    /// is to be decoded.
    var encode: Bool? { base.encode == nil ? options.`init` : base.encode! }

    /// Indicates the initialization type for this variable.
    ///
    /// Following checks are performed to determine initialization type:
    /// * Initialization is ignored if variable can't be initialized
    ///   (i.e. `options.init` is `false`).
    /// * Initialization is optional if variable is already initialized
    ///   and can be initialized again (i.e both `options.initialized`
    ///   and `options.init` is `true`)
    /// * Otherwise initialization type of the underlying variable value
    ///   is used.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: MacroExpansionContext
    ) -> AnyInitialization {
        return if options.`init` {
            if options.initialized {
                base.initializing(in: context).optionalize.any
            } else {
                base.initializing(in: context).any
            }
        } else {
            IgnoredInitialization().any
        }
    }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for decoding of the underlying
    /// variable value if variable can be initialized
    /// (i.e. `options.init` is `true`). Otherwise variable
    /// ignored in decoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        guard options.`init` else { return .init([]) }
        return base.decoding(in: context, from: location)
    }
}
