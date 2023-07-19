/// A type representing builder that uses optional registrations to partake
/// in the code generation.
///
/// The optional registration is used to update registration data with current syntax.
/// If optional registration not provided, input registration is passed with variable type erased.
struct OptionalRegistrationBuilder<Builder>: RegistrationBuilder
where Builder: RegistrationBuilder {
    typealias Input = Builder.Input
    /// The optional builder to use.
    ///
    /// This will be used as underlying
    /// `build(with:)` implementation.
    let base: Builder?
    
    /// Creates a new instance from the provided optional builder.
    ///
    /// The provided builder will be used as underlying `build(with:)`
    /// implementation.
    ///
    /// - Parameter base: The optional `RegistrationBuilder` to use.
    /// - Returns: Newly created `RegistrationBuilder`.
    init(base: Builder?) {
        self.base = base
    }

    /// Build new registration with provided input registration.
    ///
    /// Uses optional `base` to add additional data based on the current syntax.
    /// If the optional registration not present, input registration is passed with
    /// variable type erased.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data.
    func build(with input: Registration<Input>) -> Registration<AnyVariable> {
        let keyPath: [String]
        let variable: Variable
        if let reg = base?.build(with: input) {
            keyPath = reg.keyPath
            variable = reg.variable
        } else {
            keyPath = input.keyPath
            variable = input.variable
        }
        return input
            .updating(with: keyPath)
            .updating(with: AnyVariable(base: variable))
    }
}
