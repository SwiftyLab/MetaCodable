/// Indicates the field needs to be decoded to a specific
/// `CodingKey` path provided, different from the encoding path.
///
/// See ``CodedAt(_:)`` for all configurations and use-cases.
///
/// - Parameter path: The `CodingKey` path value located at for decoding only.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable(commonStrategies:)`` macro uses this macro
///   when generating final implementations.
///
/// - Important: When applied to fields, the field type must confirm to
///   `Decodable`.
///
/// - Important: This macro affects only decoding operations. Encoding will use
///   the default variable name or any encoding path specified with ``EncodedAt(_:)``.
@attached(peer)
@available(swift 5.9)
public macro DecodedAt(_ path: StaticString...) = #externalMacro(
    module: "MacroPlugin", type: "DecodedAt"
)
