/// Indicates the field needs to be encoded to a specific
/// `CodingKey` path provided, different from the decoding path.
///
/// See ``CodedAt(_:)`` for all configurations and use-cases.
///
/// - Parameter path: The `CodingKey` path value located at for encoding only.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable(commonStrategies:)`` macro uses this macro
///   when generating final implementations.
///
/// - Important: When applied to fields, the field type must confirm to
///   `Encodable`.
///
/// - Important: This macro affects only encoding operations. Decoding will use
///   the default variable name or any encoding path specified with ``DecodedAt(_:)``.
@attached(peer)
@available(swift 5.9)
public macro EncodedAt(_ path: StaticString...) = #externalMacro(
    module: "MacroPlugin", type: "EncodedAt"
)
