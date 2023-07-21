import SwiftSyntax
import SwiftSyntaxMacros

/// A type-erased variable value only containing initialization type data.
///
/// The `AnyVariable` type forwards `Variable` implementations to an underlying
/// variable value, hiding the type of the wrapped value.
struct AnyVariable<Initialization: VariableInitialization>: Variable {
    /// The value wrapped by this instance.
    ///
    /// The base property can be cast back
    /// to its original type using type casting
    /// operators (`as?`, `as!`, or `as`).
    let base: any Variable<Initialization>

    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }
    /// Whether the variable is needed for final code generation.
    ///
    /// Provides whether underlying variable value is needed
    /// for final code generation.
    var canBeRegistered: Bool { base.canBeRegistered }

    /// Indicates the initialization type for this variable.
    ///
    /// Provides initialization type of the underlying variable value.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> Initialization {
        return base.initializing(in: context)
    }

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
        in context: some MacroExpansionContext,
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
        in context: some MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        return base.encoding(in: context, to: location)
    }
}
