@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A default associated variable value with basic functionalities.
///
/// The `BasicAssociatedVariable` uses `BasicPropertyVariable` type
/// for default decoding/encoding implementations.
struct BasicAssociatedVariable: AssociatedVariable, ComposedVariable,
    DeclaredVariable, DefaultPropertyVariable
{
    /// The value wrapped by this instance.
    ///
    /// The `BasicPropertyVariable` type
    /// providing actual implementations.
    let base: BasicPropertyVariable
    /// The label of the variable.
    ///
    /// The label is provided during
    /// initialization of this variable.
    let label: TokenSyntax?

    /// Whether the variable is to be decoded.
    ///
    /// Whether underlying wrapped variable is to be decoded.
    var decode: Bool? { base.decode }
    /// Whether the variable is to be encoded.
    ///
    /// Whether underlying wrapped variable is to be encoded.
    var encode: Bool? { base.encode }

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Whether underlying wrapped variable requires `Decodable` conformance.
    var requireDecodable: Bool? { base.requireDecodable }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Whether underlying wrapped variable requires `Encodable` conformance.
    var requireEncodable: Bool? { base.requireEncodable }

    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses the declaration to read variable specific data,
    /// i.e. `name`, `type`, `value`, `label`.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    init(
        from decl: AssociatedDeclSyntax, in context: some MacroExpansionContext
    ) {
        self.label = decl.param.firstName?.trimmed
        self.base = .init(
            name: decl.name, type: decl.param.type,
            value: decl.param.defaultValue?.value,
            decodePrefix: "let ", encodePrefix: ""
        )
    }
}

extension BasicAssociatedVariable: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = BasicPropertyVariable.Initialization
}
