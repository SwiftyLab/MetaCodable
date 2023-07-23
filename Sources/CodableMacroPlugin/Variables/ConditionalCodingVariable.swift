import SwiftSyntax
import SwiftSyntaxMacros

/// A variable value containing data whether to perform decoding/encoding.
///
/// The `ConditionalCodingVariable` type forwards `Variable`
/// decoding/encoding implementations based on condition satisfied otherwise
/// no decoding/encoding code is generated, while customizing decoding.
/// The initialization implementation is forwarded without any check.
struct ConditionalCodingVariable<Var: Variable>: Variable {
    /// The customization options for `ConditionalCodingVariable`.
    ///
    /// `ConditionalCodingVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// Whether variable needs to be decoded.
        ///
        /// True for non-initialized stored variables.
        /// False for variables with `@IgnoreCoding`
        /// and `@IgnoreDecoding` attributes.
        let decode: Bool
        /// Whether variable should to be encoded.
        ///
        /// False for variables with `@IgnoreCoding`
        /// and `@IgnoreEncoding` attributes.
        let encode: Bool
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
    /// Provides whether underlying variable value
    /// is needed for final code generation or variable
    /// was asked to be decoded/encoded explicitly.
    var canBeRegistered: Bool {
        return base.canBeRegistered || options.decode || options.encode
    }

    /// Indicates the initialization type for this variable.
    ///
    /// Forwards implementation to underlying variable value.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> Var.Initialization {
        return base.initializing(in: context)
    }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for decoding of the underlying
    /// variable value if variable is to be decoded
    /// (i.e. `options.decode` is `true`). Otherwise
    /// variable ignored in decoding.
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
        guard options.decode else { return .init([]) }
        return base.decoding(in: context, from: location)
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for encoding of the underlying
    /// variable value if variable is to be encoded
    /// (i.e. `options.encode` is `true`). Otherwise
    /// variable ignored in encoding.
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
        guard options.encode else { return .init([]) }
        return base.encoding(in: context, to: location)
    }
}
