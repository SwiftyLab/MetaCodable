import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// A variable value containing initialization data.
///
/// The `InitializationVariable` type forwards `Variable`
/// encoding implementations, while customizing decoding and initialization
/// implementations.
struct InitializationVariable<V: Variable>: Variable {
    /// The customization option for `InitializationVariable`.
    ///
    /// `InitializationVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Option {
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
    let base: V
    /// The option for customizations.
    ///
    /// Option is provided during initialization.
    let option: Option

    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }
    /// Whether the variable is needed
    /// for final code generation.
    ///
    /// If the variable can not be initialized
    /// then variable is ignored.
    var canBeRegistered: Bool { option.`init` }

    /// Indicates the initialization type for this variable.
    ///
    /// Following checks are performed to determine initialization type:
    /// * Initialization is ignored if variable can't be initialized
    ///   (i.e. `option.init` is `false`).
    /// * Initialization is optional if variable is already initialized
    ///   and can be initialized again (i.e both `option.initialized`
    ///   and `option.init` is `true`)
    /// * Otherwise initialization type of the underlying variable value is used.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> VariableInitialization {
        return if option.`init` {
            if option.initialized {
                base.initializing(in: context).optionalize
            } else {
                base.initializing(in: context)
            }
        } else {
            .ignored
        }
    }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for decoding of the underlying
    /// variable value if variable can be initialized
    /// (i.e. `option.init` is `true`). Otherwise variable
    /// ignored in decoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        guard option.`init` else { return .init([]) }
        return base.decoding(in: context, from: location)
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for encoding of the underlying
    /// variable value.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        return base.encoding(in: context, to: location)
    }
}
