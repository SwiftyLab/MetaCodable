import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing a variable composed with another
/// variable.
///
/// This type informs how the variable needs to be initialized,
/// decoded and encoded in the macro code generation phase.
///
/// This variable adds customization on top of underlying
/// wrapped variable's implementation.
protocol ComposedVariable<Wrapped>: Variable
where CodingLocation == Wrapped.CodingLocation, Generated == Wrapped.Generated {
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
        from location: Wrapped.CodingLocation
    ) -> Wrapped.Generated {
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
        to location: Wrapped.CodingLocation
    ) -> Wrapped.Generated {
        return base.encoding(in: context, to: location)
    }
}

extension ComposedVariable where Self: NamedVariable, Wrapped: NamedVariable {
    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
}

extension ComposedVariable where Self: ValuedVariable, Wrapped: ValuedVariable {
    /// The value of the variable.
    ///
    /// Provides value of the underlying variable value.
    var value: ExprSyntax? { base.value }
}

extension ComposedVariable
where Self: ConditionalVariable, Wrapped: ConditionalVariable {
    /// Whether the variable is to be decoded.
    ///
    /// Whether underlying wrapped variable is to be decoded.
    var decode: Bool? { base.decode }
    /// Whether the variable is to be encoded.
    ///
    /// Whether underlying wrapped variable is to be encoded.
    var encode: Bool? { base.encode }

    /// The arguments passed to encoding condition.
    ///
    /// Provides arguments of underlying variable value.
    var conditionArguments: LabeledExprListSyntax {
        return base.conditionArguments
    }
}

extension ComposedVariable
where Self: PropertyVariable, Wrapped: PropertyVariable {
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Whether underlying wrapped variable requires `Decodable` conformance.
    var requireDecodable: Bool? { base.requireDecodable }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Whether underlying wrapped variable requires `Encodable` conformance.
    var requireEncodable: Bool? { base.requireEncodable }

    /// The prefix token to use along with `name` when decoding.
    ///
    /// Provides decode prefix of the underlying variable value.
    var decodePrefix: TokenSyntax { base.decodePrefix }
    /// The prefix token to use along with `name` when encoding.
    ///
    /// Provides encode prefix of the underlying variable value.
    var encodePrefix: TokenSyntax { base.encodePrefix }

    /// The fallback behavior when decoding fails.
    ///
    /// In the event this decoding this variable is failed,
    /// appropriate fallback would be applied.
    ///
    /// Provides fallback for the underlying variable value.
    var decodingFallback: DecodingFallback { base.decodingFallback }

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

extension ComposedVariable
where
    Self: InitializableVariable, Wrapped: InitializableVariable,
    Initialization == Wrapped.Initialization
{
    /// Indicates the initialization type for this variable.
    ///
    /// Forwards implementation to underlying variable value.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(in context: some MacroExpansionContext) -> Initialization
    where Initialization == Wrapped.Initialization {
        return base.initializing(in: context)
    }
}

extension ComposedVariable
where Self: AssociatedVariable, Wrapped: AssociatedVariable {
    /// The label of the variable.
    ///
    /// Provides label of the underlying variable value.
    var label: TokenSyntax? { base.label }
}

extension ComposedVariable
where Self: EnumCaseVariable, Wrapped: EnumCaseVariable {
    /// All the associated variables for this case.
    ///
    /// Provides associated variables of the underlying variable value.
    var variables: [any AssociatedVariable] { base.variables }
}

extension ComposedVariable where Self: TypeVariable, Wrapped: TypeVariable {
    /// Provides the syntax for `CodingKeys` declarations.
    ///
    /// Provides members generated by the underlying variable value.
    ///
    /// - Parameters:
    ///   - protocols: The protocols for which conformance generated.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The `CodingKeys` declarations.
    func codingKeys(
        confirmingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        return base.codingKeys(confirmingTo: protocols, in: context)
    }
}
