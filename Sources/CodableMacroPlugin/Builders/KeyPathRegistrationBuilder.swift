import SwiftSyntax

/// A registration builder updating explicit decoding/encoding
/// and `CodingKey` path data for variable.
///
/// The `CodingKey` path is updated using the provided builder
/// and explicit decoding/encoding is indicated if provider is
/// `provided` with explicit data.
struct KeyPathRegistrationBuilder<Input: Variable>: RegistrationBuilder {
    /// The output registration variable data handling
    /// whether variable is asked to explicitly decode/encode
    /// using `CodedAt` or `CodedIn` macro.
    typealias Output = KeyedVariable<Input>

    /// The `CodingKey` path provider.
    ///
    /// Current `CodingKey` path is
    /// updated by this provider.
    let provider: any KeyPathProvider

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with the provided `CodingKey` path from provider,
    /// updating current `CodingKey` path data.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional `CodingKey` path data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let options = Output.Options(code: provider.provided)
        let newVar = Output(base: input.variable, options: options)
        let output = input.updating(with: newVar)
        guard provider.provided else { return output }
        return output.adding(attribute: provider)
            .updating(with: provider.keyPath(withExisting: input.keyPath))
    }
}
