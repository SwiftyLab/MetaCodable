/// Generate `Codable` implementation of `struct`, `class`, `enum`, `actor`
/// and `protocol` types by leveraging custom attributes provided on variable
/// declarations.
///
/// # Usage
/// By default the field name is used as `CodingKey` for the field value during
/// encoding and decoding. Following customization can be done on fields to
/// provide custom decode and encode behavior:
///   * Use ``CodedAt(_:)`` providing single string value as custom coding key.
///   * Use ``CodedAt(_:)`` providing multiple string value as nested coding
///     key path.
///   * Use ``CodedIn(_:)`` with one or more string value as nested container
///     coding key path, with variable name as coding key.
///   * Use ``CodedAt(_:)`` with no path arguments, when type is composition
///     of multiple `Codable` types.
///   * Use ``CodedAs(_:_:)`` to provide additional coding key values where
///     field value can appear.
///   * Use ``CodedBy(_:)`` to provide custom decoding/encoding behavior for
///     `Codable` types or implement decoding/encoding for non-`Codable` types.
///   * Use ``Default(_:)`` to provide default value when decoding fails.
///   * Use ``CodedAs(_:_:)`` to provide custom values for enum cases.
///   * Use ``CodedAt(_:)`` to provide enum-case/protocol identifier tag path.
///   * Use ``CodedAs()`` to provide enum-case/protocol identifier tag type.
///   * Use ``ContentAt(_:_:)`` to provided enum-case/protocol content path.
///   * Use ``IgnoreCoding()``, ``IgnoreDecoding()`` and
///     ``IgnoreEncoding()`` to ignore specific properties/cases/types from
///     decoding/encoding or both.
///   * Use ``IgnoreEncoding(if:)-1iuvv`` and ``IgnoreEncoding(if:)-7toka``
///     to ignore encoding based on custom conditions.
///   * Use ``CodingKeys(_:)`` to work with different case style `CodingKey`s.
///   * Use ``IgnoreCodingInitialized()`` to ignore decoding and encoding
///     all initialized properties/case associated variables.
///   * Generate protocol decoding/encoding ``HelperCoder``s with build tool
///     plugin `MetaProtocolCodable` from ``DynamicCodable`` types.
///
/// # Effect
/// This macro composes extension macro expansion depending on `Codable`
/// conformance of type:
///   * Extension macro expansion, to confirm to `Decodable` or `Encodable`
///     protocols depending on whether type doesn't already conform to `Decodable`
///     or `Encodable` respectively.
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Codable` implementation of both `init(from:)` and `encode(to:)`
///     methods.
///   * If attached declaration already conforms to `Codable` this macro expansion
///     is skipped.
///
/// - Important: The attached declaration must be of a `struct`, `class`, `enum`
///   or `actor` type. [See the limitations for this macro](<doc:Limitations>).
@attached(
    extension, conformances: Decodable, Encodable,
    names: named(CodingKeys), named(DecodingKeys),
    named(init(from:)), named(encode(to:))
)
@attached(
    member, conformances: Decodable, Encodable,
    names: named(CodingKeys), named(init(from:)), named(encode(to:))
)
@available(swift 5.9)
public macro Codable() =
    #externalMacro(module: "MacroPlugin", type: "Codable")

/// Indicates whether super class conforms to `Codable` or not.
///
/// By default, ``Codable()`` assumes class inherits `Decodable`
/// or `Encodable` conformance if it doesn't receive protocol needs
/// to be conformed from the compiler. Using this macro, it can be explicitly
/// indicated that the class doesn't inherit conformance in such cases.
///
/// Following code indicates ``Codable()`` that `Item` class doesn't
/// inherit conformance:
/// ```swift
/// @Codable
/// @Model
/// @Inherits(decodable: false, encodable: false)
/// final class Item {
///     @CodedAt("timestamp")
///     var timestamp: Date? = nil
///
///     init() { }
/// }
/// ```
///
/// - Parameters:
///   - decodable: Whether super class conforms to `Decodable`.
///   - encodable: Whether super class conforms to `Encodable`.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a class declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro Inherits(decodable: Bool, encodable: Bool) =
    #externalMacro(module: "MacroPlugin", type: "Inherits")
