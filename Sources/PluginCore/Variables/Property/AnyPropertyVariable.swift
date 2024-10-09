import SwiftSyntax
import SwiftSyntaxMacros

/// A type-erased variable value only containing initialization type data.
///
/// The `AnyPropertyVariable` type forwards `Variable` implementations
/// to an underlying variable value, hiding the type of the wrapped value.
struct AnyPropertyVariable<Initialization>: PropertyVariable
where Initialization: VariableInitialization {
    /// The value wrapped by this instance.
    ///
    /// The base property can be cast back
    /// to its original type using type casting
    /// operators (`as?`, `as!`, or `as`).
    let base: any PropertyVariable
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
    /// The value of the variable.
    ///
    /// Provides value of the underlying variable value.
    var value: ExprSyntax? { base.value }

    /// The prefix token to use along with `name` when decoding.
    ///
    /// Provides underlying variable value decode prefix.
    var decodePrefix: TokenSyntax { base.decodePrefix }
    /// The prefix token to use along with `name` when encoding.
    ///
    /// Provides underlying variable value encode prefix.
    var encodePrefix: TokenSyntax { base.encodePrefix }

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

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Decodable` conformance.
    var requireDecodable: Bool? { base.requireDecodable }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Encodable` conformance.
    var requireEncodable: Bool? { base.requireEncodable }

    /// The fallback behavior when decoding fails.
    ///
    /// In the event this decoding this variable is failed,
    /// appropriate fallback would be applied.
    ///
    /// Provides fallback for the underlying variable value.
    var decodingFallback: DecodingFallback { base.decodingFallback }

    /// Wraps the provided variable erasing its type and
    /// initialization type.
    ///
    /// The implementation is kept unchanged while
    /// erasing this type and initialization type.
    ///
    /// - Parameter base: The underlying variable value.
    /// - Returns: Newly created variable.
    init(base: some PropertyVariable<Initialization>) {
        self.base = base
        self.initialization = { base.initializing(in: $0) }
    }

    /// Wraps the provided variable erasing its type.
    ///
    /// The implementation is kept unchanged while
    /// erasing this type, initialization type is not erased.
    /// - Parameter base: The underlying variable value.
    /// - Returns: Newly created variable.
    init<Var: PropertyVariable>(base: Var)
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
        in context: some MacroExpansionContext
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
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
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
        to location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        return base.encoding(in: context, to: location)
    }

    /// The number of variables this variable depends on.
    ///
    /// Provides the number of variables underlying variable depends on.
    var dependenciesCount: UInt { base.dependenciesCount }

    /// Checks whether this variable is dependent on the provided variable.
    ///
    /// Provides whether provided variable needs to be decoded first,
    /// before decoding underlying variable value.
    ///
    /// - Parameter variable: The variable to check for.
    /// - Returns: Whether this variable is dependent on the provided variable.
    func depends<Variable: PropertyVariable>(on variable: Variable) -> Bool {
        return base.depends(on: variable)
    }
}

extension AnyPropertyVariable: AssociatedVariable
where Initialization: RequiredVariableInitialization {
    /// The label of the variable.
    ///
    /// Provides label of the underlying associated variable value,
    /// `nil` if underlying variable not associated variable.
    var label: TokenSyntax? {
        guard let base = base as? any AssociatedVariable else { return nil }
        return base.label
    }
}

extension PropertyVariable where Initialization: VariableInitialization {
    /// Erase type of this variable.
    ///
    /// Wraps this variable in an `AnyPropertyVariable` instance.
    /// The implementation stays unchanged while type is erased.
    var any: AnyPropertyVariable<Self.Initialization> {
        return .init(base: self)
    }
}

extension PropertyVariable
where Initialization: RequiredVariableInitialization {
    /// Erase type of this variable and initialization type.
    ///
    /// Wraps this variable in an `AnyPropertyVariable` instance and the initialization
    /// type in `AnyRequiredVariableInitialization`. The implementation
    /// stays unchanged while type is erased.
    var any: AnyPropertyVariable<AnyRequiredVariableInitialization> {
        return .init(base: self)
    }
}
