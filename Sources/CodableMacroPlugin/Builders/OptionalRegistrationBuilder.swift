/// An extension representing builder that uses wrapped optional
/// registrations to partake in the code generation.
///
/// The optional registration is used to update registration data with
/// current syntax. If optional registration not provided, input registration
/// is passed with default output options.
extension Optional: RegistrationBuilder
    where
    Wrapped: RegistrationBuilder,
    Wrapped.Output: DefaultOptionComposedVariable,
    Wrapped.Input == Wrapped.Output.Wrapped
{
    /// The variable data of underlying builder's input registration.
    typealias Input = Wrapped.Input
    /// The variable data generated by passed builder or the input
    /// variable data if no builder passed.
    typealias Output = Wrapped.Output

    /// Build new registration with provided input registration.
    ///
    /// Uses optional `base` to add additional data based on the current
    /// syntax. If the optional registration not present, input registration
    /// is passed with default output options.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        switch self {
        case .none:
            let newVar = Wrapped.Output(base: input.variable)
            return input.updating(with: newVar)
        case let .some(wrapped):
            return wrapped.build(with: input)
        }
    }
}

/// A type representing a variable composed with another variable and
/// has some default options.
///
/// This type informs how the variable needs to be initialized, decoded
/// and encoded in the macro code generation phase.
///
/// This variable adds customization on top of underlying wrapped
/// variable's implementation and can have default options when
/// no options provided explicitly.
protocol DefaultOptionComposedVariable<Wrapped>: ComposedVariable {
    /// Creates a new instance from provided variable value.
    ///
    /// Uses default options in the implementation along
    /// with the provided variable.
    ///
    /// - Parameter base: The underlying variable value.
    /// - Returns: The newly created variable.
    init(base: Wrapped)
}
