import SwiftSyntax

/// A type-erased required initialization type.
///
/// The `AnyRequiredVariableInitialization` type forwards
/// `RequiredVariableInitialization` implementations to an
/// underlying variable value, hiding the type of the wrapped value.
struct AnyRequiredVariableInitialization: RequiredVariableInitialization {
    /// The underlying required initialization value.
    ///
    /// This function parameter and code block
    /// syntax is fetched from this value.
    let base: RequiredVariableInitialization

    /// The function parameter for the initialization function.
    ///
    /// Provides function parameter syntax of underlying initialization.
    var param: FunctionParameterSyntax { base.param }
    /// The code needs to be added to initialization function.
    ///
    /// Provides code block syntax of underlying initialization.
    var code: CodeBlockItemSyntax { base.code }

    /// Adds current initialization type to memberwise initialization
    /// generator.
    ///
    /// New memberwise initialization generator is created after adding this
    /// initialization as required and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        return base.add(to: generator)
    }
}
