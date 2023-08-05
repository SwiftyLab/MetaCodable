extension IgnoreCodingInitialized: RegistrationBuilder {
    /// The basic variable data that input registration can have.
    typealias Input = BasicVariable
    /// The output registration variable type that handles conditional
    /// decoding/encoding data.
    typealias Output = ConditionalCodingVariable<Input>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with decoding and encoding condition
    /// depending on whether already initialized. Already initialized variables
    /// are updated to be ignored in decoding/encoding.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with helper expression data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let code = input.context.binding.initializer == nil
        let options = Output.Options(decode: code, encode: code)
        let newVariable = Output(base: input.variable, options: options)
        return input.updating(with: newVariable)
    }
}
