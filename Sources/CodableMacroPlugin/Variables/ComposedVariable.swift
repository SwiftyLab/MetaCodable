@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing a variable composed with another
/// variable.
///
/// This type informs how the variable needs to be initialized,
/// decoded and encoded in the macro code generation phase.
///
/// This variable adds customization on top of underlying
/// wrapped variable's implementation.
protocol ComposedVariable<Wrapped>: Variable {
    /// A type representing the underlying
    /// wrapped variable.
    ///
    /// The wrapped variable's type data is
    /// preserved and used to add restriction
    /// in chaining order of code generation
    /// implementations.
    associatedtype Wrapped: Variable
    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and this variable is used
    /// to chain code generation implementations.
    var base: Wrapped { get }
}

extension ComposedVariable {
    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for decoding of the underlying
    /// variable value.
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
        in context: MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        return base.encoding(in: context, to: location)
    }
}

extension ComposedVariable where Initialization == Wrapped.Initialization {
    /// Indicates the initialization type for this variable.
    ///
    /// Forwards implementation to underlying variable value.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(in context: MacroExpansionContext) -> Initialization {
        return base.initializing(in: context)
    }
}
