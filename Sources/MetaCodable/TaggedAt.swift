/// Indicates the enum-case needs to be decoded/encoded by identifying the case
/// at the `CodingKey` path provided.
///
/// The value at the provided `CodingKey` path is decoded/encoded as `String`
/// unless different type specified with ``CodedAs()`` and compared with value
/// for each enum-case. i.e. for enum:
/// ```swift
/// @Codable
/// @TaggedAt("type")
/// enum Command {
///     case load(key: String)
///     case store(key: String, value: Int)
/// }
/// ```
/// the encoded JSON for internally tagged enum will be of following variations:
/// ```json
/// { "key": "MyKey", "type": "load" }
/// ```
/// ```json
/// { "key": "MyKey", "value": 42, "type": "store" }
/// ```
///
/// - Parameter path: The `CodingKey` path the identifier tag for enum
///   located at.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro TaggedAt(_ path: StaticString, _: StaticString...) =
    #externalMacro(module: "CodableMacroPlugin", type: "TaggedAt")
