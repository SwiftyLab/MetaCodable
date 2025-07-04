/// Generate `Encodable` implementation of `struct`, `class`, `enum`, `actor`
/// and `protocol` types by leveraging custom attributes provided on variable
/// declarations. This macro is named `ConformEncodable` to avoid conflicts
/// with the standard library `Encodable` protocol.
///
/// # Usage
/// By default the field name is used as `CodingKey` for the field value during
/// encoding. Following customization can be done on fields to
/// provide custom encode behavior:
///   * Use ``CodedAt(_:)`` providing single string value as custom coding key.
///   * Use ``CodedAt(_:)`` providing multiple string value as nested coding
///     key path.
///   * Use ``CodedIn(_:)`` with one or more string value as nested container
///     coding key path, with variable name as coding key.
///   * Use ``CodedAt(_:)`` with no path arguments, when type is composition
///     of multiple `Encodable` types.
///   * Use ``CodedAs(_:_:)`` to provide additional coding key values where
///     field value can appear.
///   * Use ``CodedBy(_:)`` to provide custom encoding behavior for
///     `Encodable` types or implement encoding for non-`Encodable` types.
///   * Use ``CodedAs(_:_:)`` to provide custom values for enum cases.
///   * Use ``CodedAt(_:)`` to provide enum-case/protocol identifier tag path.
///   * Use ``CodedAs()`` to provide enum-case/protocol identifier tag type.
///   * Use ``ContentAt(_:_:)`` to provided enum-case/protocol content path.
///   * Use ``IgnoreCoding()``, ``IgnoreEncoding()`` to ignore specific 
///     properties/cases/types from encoding.
///   * Use ``IgnoreEncoding(if:)-1iuvv`` and ``IgnoreEncoding(if:)-7toka``
///     to ignore encoding based on custom conditions.
///   * Use ``CodingKeys(_:)`` to work with different case style `CodingKey`s.
///   * Use ``IgnoreCodingInitialized()`` to ignore encoding
///     all initialized properties/case associated variables.
///
/// # Effect
/// This macro composes extension macro expansion for `Encodable`
/// conformance of type:
///   * Extension macro expansion, to confirm to `Encodable` protocol
///     if the type doesn't already conform to `Encodable`.
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Encodable` implementation of `encode(to:)` method.
///   * If attached declaration already conforms to `Encodable` this macro expansion
///     is skipped.
///
/// - Parameters:
///   - commonStrategies: An array of CodableCommonStrategy values specifying
///   type conversion strategies to be automatically applied to all properties of the type.
///
/// - Important: The attached declaration must be of a `struct`, `class`, `enum`
///   or `actor` type. [See the limitations for this macro](<doc:Limitations>).
@attached(
    extension, conformances: Encodable,
    names: named(CodingKeys), named(encode(to:))
)
@attached(
    member, conformances: Encodable,
    names: named(CodingKeys), named(encode(to:))
)
@available(swift 5.9)
public macro ConformEncodable(commonStrategies: [CodableCommonStrategy] = []) =
    #externalMacro(module: "MacroPlugin", type: "ConformEncodable")
