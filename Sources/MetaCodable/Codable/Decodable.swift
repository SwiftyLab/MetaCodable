/// Generate `Decodable` implementation of `struct`, `class`, `enum`, `actor`
/// and `protocol` types by leveraging custom attributes provided on variable
/// declarations. This macro is named `ConformDecodable` to avoid conflicts
/// with the standard library `Decodable` protocol.
///
/// # Usage
/// By default the field name is used as `CodingKey` for the field value during
/// decoding. Following customization can be done on fields to
/// provide custom decode behavior:
///   * Use ``CodedAt(_:)`` providing single string value as custom coding key.
///   * Use ``CodedAt(_:)`` providing multiple string value as nested coding
///     key path.
///   * Use ``CodedIn(_:)`` with one or more string value as nested container
///     coding key path, with variable name as coding key.
///   * Use ``CodedAt(_:)`` with no path arguments, when type is composition
///     of multiple `Decodable` types.
///   * Use ``CodedBy(_:)`` to provide custom decoding behavior for
///     `Decodable` types or implement decoding for non-`Decodable` types.
///   * Use ``Default(_:)`` to provide default value when decoding fails.
///   * Use ``CodedAs(_:_:)`` to provide custom values for enum cases.
///   * Use ``CodedAt(_:)`` to provide enum-case/protocol identifier tag path.
///   * Use ``CodedAs()`` to provide enum-case/protocol identifier tag type.
///   * Use ``ContentAt(_:_:)`` to provided enum-case/protocol content path.
///   * Use ``IgnoreCoding()``, ``IgnoreDecoding()`` to ignore specific
///     properties/cases/types from decoding.
///   * Use ``CodingKeys(_:)`` to work with different case style `CodingKey`s.
///   * Use ``IgnoreCodingInitialized()`` to ignore decoding
///     all initialized properties/case associated variables.
///
/// # Effect
/// This macro composes extension macro expansion for `Decodable`
/// conformance of type:
///   * Extension macro expansion, to confirm to `Decodable` protocol
///     if the type doesn't already conform to `Decodable`.
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Decodable` implementation of `init(from:)` method.
///   * If attached declaration already conforms to `Decodable` this macro expansion
///     is skipped.
///
/// - Parameters:
///   - commonStrategies: An array of CodableCommonStrategy values specifying
///   type conversion strategies to be automatically applied to all properties of the type.
///
/// - Important: The attached declaration must be of a `struct`, `class`, `enum`
///   or `actor` type. [See the limitations for this macro](<doc:Limitations>).
@attached(
    extension, conformances: Decodable,
    names: named(CodingKeys), named(DecodingKeys), named(init(from:))
)
@attached(
    member, conformances: Decodable,
    names: named(CodingKeys), named(init(from:))
)
@available(swift 5.9)
public macro ConformDecodable(commonStrategies: [CodableCommonStrategy] = []) =
    #externalMacro(module: "MacroPlugin", type: "ConformDecodable")
