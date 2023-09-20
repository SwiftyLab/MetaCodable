import SwiftSyntax

/// Represents initialization is required for the variable
/// and default value is provided.
///
/// The variable must not be initialized already and
/// must be a stored property.
struct RequiredInitializationWithDefaultValue: RequiredVariableInitialization {
    /// The underlying required initialization value.
    ///
    /// This function parameter and code block
    /// syntax is fetched from this value and
    /// updated when adding this initialization
    /// type to init-generator.
    let base: RequiredInitialization
    /// The default expression when
    /// no value provided explicitly.
    ///
    /// This expression is provided
    /// during initialization and used
    /// to generate required initialization
    /// with default value.
    let expr: ExprSyntax

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
    /// initialization as required with default value and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        var param = base.param
        param.defaultValue = .init(value: expr)
        return generator.add(.init(param: param, code: base.code))
    }
}
