/// A type representing builder that builds failable registrations to partake in the code generation.
///
/// These builders update the input registration with data from current syntax. If registration building fails,
/// input registration is passed type erased.
protocol OptionalRegistrationBuilder<Input, Optional>: RegistrationBuilder
where Output == AnyVariable {
    /// The optional registration variable type.
    associatedtype Optional: Variable
    /// Build new registration with provided input registration.
    ///
    /// New registration might fail to build and can have additional
    /// data based on the current syntax without the macro expansion.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data or `nil`.
    func build(with input: Registration<Input>) -> Registration<Optional>?
}

extension OptionalRegistrationBuilder {
    /// Build new registration with provided input registration.
    ///
    /// Uses optional `build(with:)` method to add additional data based on the current syntax.
    /// If the optional registration fails to build input registration is passed with variable type erased.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let keyPath: [String]
        let variable: Variable
        if let reg = self.build(with: input) {
            keyPath = reg.keyPath
            variable = reg.variable
        } else {
            keyPath = input.keyPath
            variable = input.variable
        }
        return
            input
            .updating(with: keyPath)
            .updating(with: AnyVariable(base: variable))
    }
}
