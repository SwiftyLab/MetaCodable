/// A registration builder that combines one optional builder with a fallback builder.
///
/// Initializes builder action with optional builder's action if provided,
/// otherwise fallback builder's action is used.
struct ExhaustiveRegistrationBuilder<Input, Output>: RegistrationBuilder
where Input: Variable, Output: Variable {
    /// The builder action to use.
    ///
    /// This action handles `RegistrationBuilder` implementation.
    let builder: (Registration<Input>) -> Registration<Output>

    /// Creates a new instance from the provided optional and fallback builders.
    ///
    /// The builder action is initialized with optional builder's action if provided,
    /// otherwise fallback builder's action is used.
    ///
    /// - Parameters:
    ///   - optional: The optional `RegistrationBuilder` to use.
    ///   - fallback: The fallback `RegistrationBuilder` to use
    ///               if no optional builder provided.
    ///
    /// - Returns: Newly created `RegistrationBuilder`.
    init<Optional: RegistrationBuilder, Fallback: RegistrationBuilder>(
        optional: Optional?, fallback: Fallback
    )
    where
        Optional.Input == Input, Fallback.Input == Input,
        Optional.Output == Output, Fallback.Output == Output
    {
        self.builder = optional?.build ?? fallback.build
    }

    /// Build new registration with provided input registration.
    ///
    /// New registration can have additional data based on
    /// the builder action provided during initialization.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        return builder(input)
    }
}
