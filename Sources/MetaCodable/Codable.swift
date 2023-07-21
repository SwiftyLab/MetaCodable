/// Generate `Codable` implementation of `struct` types by leveraging custom
/// attributes provided on variable declarations.
///
/// # Usage
/// By default the field name is used as `CodingKey` for the field value during
/// encoding and decoding. Following customization can be done on fields to
/// provide custom decode and encode behavior:
///   * Use ``CodedAt(_:)`` providing single string value as custom coding key.
///   * Use ``CodedAt(_:)`` providing multiple string value as nested coding key path
///   * Use ``CodedIn(_:)`` with one or more string value as nested container coding
///     key path, with variable name as coding key.
///   * Use ``CodedAt(_:)`` with no path arguments, when type is composition
///     of multiple `Codable` types.
///   * Use ``CodedBy(_:)`` to provide custom decoding/encoding behavior for
///     `Codable` types or implement decoding/encoding for non-`Codable` types.
///   * Use ``Default(_:)`` to provide default value when decoding fails.
///
/// # Effect
/// This macro composes two different kinds of macro expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type for
///     the attached struct declaration named `CodingKeys` and use this type
///     for `Codable` implementation of both `init(from:)` and `encode(to:)`
///     methods. Additionally member-wise initializer(s) also generated.
///
/// - Important: The attached declaration must be of a struct type.
@attached(member, names: named(CodingKeys), named(init(from:)), named(encode(to:)), arbitrary)
@attached(conformance)
@available(swift 5.9)
public macro Codable()
= #externalMacro(module: "CodableMacroPlugin", type: "Codable")
