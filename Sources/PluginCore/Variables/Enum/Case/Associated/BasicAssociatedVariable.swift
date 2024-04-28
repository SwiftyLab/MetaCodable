import SwiftSyntax
import SwiftSyntaxMacros

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
    /// The fallback behavior when decoding fails.
    ///
    /// This fallback behavior will be used if provided,
    /// otherwise fallback behavior of base will be used.
    let fallback: DecodingFallback?

    /// The fallback behavior when decoding fails.
    ///
    /// If any fallback behavior provided it is used, otherwise
    /// fallback for the underlying variable value is used.
    var decodingFallback: DecodingFallback {
        return fallback ?? base.decodingFallback
    }

    /// Creates a new variable with provided data.
    ///
    /// This initializer can be used to add decoding fallback behavior.
    ///
    /// - Parameters:
    ///   - base: The value wrapped by this instance.
    ///   - label: The label of the variable.
    ///   - fallback: The fallback behavior when decoding fails.
    init(
        base: BasicPropertyVariable, label: TokenSyntax?,
        fallback: DecodingFallback
    ) {
        self.base = base
        self.label = label
        self.fallback = fallback
    }

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
        self.fallback = nil
        self.base = .init(
            name: decl.name, type: decl.param.type,
            value: decl.param.defaultValue?.value,
            decodePrefix: "", encodePrefix: ""
        )
    }
}

extension BasicAssociatedVariable: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = BasicPropertyVariable.Initialization
}
