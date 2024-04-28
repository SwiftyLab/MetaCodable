import SwiftSyntax

/// Represents required initialization type for `Variable`s inside
/// type declarations.
///
/// Represents whether `Variable`s are required to be initialized.
/// The variable must not be initialized already and must be a stored
/// property.
package protocol RequiredVariableInitialization: VariableInitialization {
    /// The function parameter for the initialization function.
    ///
    /// This function parameter needs to be added
    /// to the initialization function when generating
    /// initializer.
    var param: FunctionParameterSyntax { get }
    /// The code needs to be added to initialization function.
    ///
    /// This code block needs to be added
    /// to the initialization function when
    /// generating initializer.
    var code: CodeBlockItemSyntax { get }
}

extension RequiredVariableInitialization {
    /// Converts initialization to optional from required initialization.
    ///
    /// Wraps current instance in `OptionalInitialization`.
    var optionalize: OptionalInitialization<Self> {
        return .init(base: self)
    }
}
