/// Indicates the enum-case associated values needs to be decoded/encoded
/// at the `CodingKey` path provided.
///
/// This attribute can be used along with ``CodedAt(_:)`` to support adjacently
/// tagged enums. The path provided represents the path where associated values
/// of each case is decoded/encoded. i.e. for JSON with following format:
/// ```json
/// {"t": "para", "c": [{...}, {...}]}
/// ```
/// ```json
/// {"t": "str", "c": "the string"}
/// ```
/// enum representation can be created:
/// ```swift
/// @Codable
/// @CodedAt("t")
/// @ContentAt("c")
/// enum Block {
///     case para([Inline]),
///     case str(String),
/// }
/// ```
///
/// - Parameter path: The `CodingKey` path enum-case content located at.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: This attribute must be used combined with ``Codable()``
///   and ``CodedAt(_:)``.
@attached(peer)
@available(swift 5.9)
public macro ContentAt(_ path: StaticString, _: StaticString...) =
    #externalMacro(module: "CodableMacroPlugin", type: "ContentAt")
