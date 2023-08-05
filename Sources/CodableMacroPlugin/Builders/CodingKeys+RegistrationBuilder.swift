extension CodingKeys: RegistrationBuilder {
    /// The basic variable data that input
    /// registration can have.
    typealias Input = BasicVariable
    /// The unchanged basic variable data
    /// that output registration will have.
    typealias Output = BasicVariable

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with the transformed `CodingKey` path
    /// based on provided `strategy`.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with transformed `CodingKey` path data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        return input.updating(with: strategy.transform(keyPath: input.keyPath))
    }
}
