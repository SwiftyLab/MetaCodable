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
    let base: any Variable
    /// The initialization type handler for this variable.
    ///
    /// By default, set as the underlying variable initialization
    /// type is provided by this handler unless changed in initializer.
    let initialization: (MacroExpansionContext) -> Initialization

    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }

    /// Whether the variable is to be decoded.
    ///
    /// Provides whether underlying variable value
    /// is to be decoded.
    var decode: Bool? { base.decode }
    /// Whether the variable is to be encoded.
    ///
    /// Provides whether underlying variable value
    /// is to be encoded.
    var encode: Bool? { base.encode }

    /// Wraps the provided variable erasing its type and
    /// initialization type.
    ///
    /// The implementation is kept unchanged while
    /// erasing this type and initialization type.
    ///
    /// - Parameter base: The underlying variable value.
    /// - Returns: Newly created variable.
    init(base: some Variable<Initialization>) {
        self.base = base
        self.initialization = base.initializing(in:)
    }

    /// Wraps the provided variable erasing its type.
    ///
    /// The implementation is kept unchanged while
    /// erasing this type, initialization type is not erased.
    /// - Parameter base: The underlying variable value.
    /// - Returns: Newly created variable.
    init<Var: Variable>(base: Var)
    where
        Var.Initialization: RequiredVariableInitialization,
        Initialization == AnyRequiredVariableInitialization
    {
        self.base = base
        self.initialization = { .init(base: base.initializing(in: $0)) }
    }

    /// Indicates the initialization type for this variable.
    ///
    /// Provides initialization type of the underlying variable value.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: MacroExpansionContext
    ) -> Initialization {
        return initialization(context)
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

extension Variable {
    /// Erase type of this variable.
    ///
    /// Wraps this variable in an `AnyVariable` instance.
    /// The implementation stays unchanged while type is erased.
    var any: AnyVariable<Self.Initialization> {
        return .init(base: self)
    }
}

extension Variable where Initialization: RequiredVariableInitialization {
    /// Erase type of this variable and initialization type.
    ///
    /// Wraps this variable in an `AnyVariable` instance and the initialization
    /// type in `AnyRequiredVariableInitialization`. The implementation
    /// stays unchanged while type is erased.
    var any: AnyVariable<AnyRequiredVariableInitialization> {
        return .init(base: self)
    }
}
