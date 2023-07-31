/// A registration builder updating conditional decoding/encoding
/// data for variable.
///
/// Checks the following criteria to decide decoding/encoding
/// condition for variable:
/// * Enables encoding for computed and initialized immutable variables,
///   if any `CodingAttribute` type macro-attribute attached.
/// * Ignores for decoding, if `@IgnoreCoding` or `@IgnoreDecoding`
///   macro attached.
/// * Ignores for encoding, if `@IgnoreCoding` or `@IgnoreEncoding`
///   macro attached.
struct ConditionalCodingBuilder<Input: Variable>: RegistrationBuilder {
    /// The output registration variable type that handles conditional
    /// decoding/encoding data.
    typealias Output = ConditionalCodingVariable<Input>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with conditional decoding/encoding data
    /// indicating whether variable needs to decoded/encoded.
    ///
    /// Checks the following criteria to decide decoding/encoding condition
    /// for variable:
    /// * Enables encoding for computed and initialized immutable variables,
    ///   if any `CodingAttribute` type macro-attribute attached.
    /// * Ignores for decoding, if `@IgnoreCoding` or `@IgnoreDecoding`
    ///   macro attached.
    /// * Ignores for encoding, if `@IgnoreCoding` or `@IgnoreEncoding`
    ///   macro attached.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with conditional
    ///            decoding/encoding data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let declaration = input.context.declaration
        let ignoreCoding = declaration.attributes(for: IgnoreCoding.self)
        let ignoreDecoding = declaration.attributes(for: IgnoreDecoding.self)
        let ignoreEncoding = declaration.attributes(for: IgnoreEncoding.self)

        let code =
            input.variable.canBeRegistered
            || input.context.attributes.contains { $0 is CodingAttribute }
        let decode = ignoreCoding.isEmpty && ignoreDecoding.isEmpty && code
        let encode = ignoreCoding.isEmpty && ignoreEncoding.isEmpty && code
        let options = Output.Options(decode: decode, encode: encode)
        let newVariable = Output(base: input.variable, options: options)
        return input.updating(with: newVariable)
    }
}

/// An attribute type indicating explicit decoding/encoding when attached
/// to variable declarations.
///
/// Attaching attributes of this type to computed properties or initialized
/// immutable properties indicates this variable should be encoded for the type.
fileprivate protocol CodingAttribute: PropertyAttribute {}
extension CodedIn: CodingAttribute {}
extension CodedAt: CodingAttribute {}
extension CodedBy: CodingAttribute {}
extension Default: CodingAttribute {}
