import SwiftSyntax

/// Represents initialization is required for the variable.
///
/// The variable must not be initialized already and must be a stored property.
struct RequiredInitialization: VariableInitialization {
    /// The function parameter for the initialization function.
    ///
    /// This function parameter needs to be added
    /// to the initialization function when generating
    /// initializer.
    let param: FunctionParameterSyntax
    /// The code needs to be added to initialization function.
    ///
    /// This code block needs to be added
    /// to the initialization function when
    /// generating initializer.
    let code: CodeBlockItemSyntax

    /// Converts initialization to optional from required initialization.
    ///
    /// Wraps current instance in `OptionalInitialization`.
    var optionalize: OptionalInitialization {
        return .init(base: self)
    }

    /// Adds current initialization type to member-wise initialization generator.
    ///
    /// New member-wise initialization generator is created after adding this
    /// initialization as required and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        generator.add(.init(param: param, code: code))
    }

    /// Updates initialization type with the provided function parameter syntax.
    ///
    /// - Parameter param: The function parameter for the initialization function.
    /// - Returns: Updated initialization type.
    func update(param: FunctionParameterSyntax) -> Self {
        return .init(param: param, code: code)
    }
}