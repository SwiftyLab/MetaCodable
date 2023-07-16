import SwiftSyntax

/// Represents the initialization type for `Variable`s inside type declarations.
///
/// Represents whether `Variable`s are required to be initialized
/// or initialization is optional. `Variable`s can also ignore initialization
/// if initialized already.
enum VariableInitialization {
    /// Represents initialization must be ignored for the variable.
    ///
    /// The variable needs to be already initialized and immutable.
    case ignored
    /// Represents initialization is required for the variable.
    ///
    /// The variable must not be initialized already.
    ///
    /// - Parameters:
    ///   - param: The function parameter needs to be added to the initialization function.
    ///   - code: The code needs to be added to initialization function.
    case required(_ param: FunctionParameterSyntax, _ code: CodeBlockItemSyntax)
    /// Represents initialization is optional for the variable.
    ///
    /// The variable must be mutable and initialized already.
    ///
    /// - Parameters:
    ///   - param: The function parameter optionally added to the initialization function.
    ///   - code: The code optionally added to initialization function.
    case optional(_ param: FunctionParameterSyntax, _ code: CodeBlockItemSyntax)

    /// Converts initialization to optional
    /// from required initialization.
    var optionalize: Self {
        switch self {
        case .required(let funcParam, let expr):
            return .optional(funcParam, expr)
        default:
            return self
        }
    }
}
