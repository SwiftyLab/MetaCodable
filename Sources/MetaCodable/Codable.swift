/// Generate `Codable` implementation of `struct` types by leveraging custom
/// attributes provided on variable declarations.
///
/// # Usage
/// By default the field name is used as `CodingKey` for the field value during
/// encoding and decoding. Following customization can be done on fields to
/// provide custom decode and encode behavior:
///   * Use ``CodablePath(_:)`` providing single string value
///     as custom coding key.
///   * Use ``CodablePath(_:)`` providing multiple string value
///     as nested coding key path.
///   * Use ``CodableCompose()`` when type is composition
///     of multiple `Codable` types.
///   * Use ``CodablePath(helper:_:)`` and ``CodableCompose(helper:)``
///     to provide custom decoding/encoding behavior for `Codable` types or
///     implement decoding/encoding for non-`Codable` types.
///   * Use ``CodablePath(default:_:)`` and ``CodableCompose(default:)``
///     to provide default value when decoding fails.
///   * ``CodablePath(default:helper:_:)`` and ``CodableCompose(default:helper:)``
///     can be used to compose all the above behaviors described.
///
/// # Effect
/// This macro composes two different kinds of macro expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type for
///     the attached struct declaration named `CodingKeys` and use this type
///     for `Codable` implementation of both `init(from:)` and `encode(to:)`
///     methods. Additionally member-wise initializer is also generated.
///
/// - Important: The attached declaration must be of a struct type.
@attached(member, names: named(CodingKeys), named(init(from:)), named(encode(to:)), arbitrary)
@attached(conformance)
public macro Codable() = #externalMacro(
    module: "CodableMacroPlugin",
    type: "CodableMacro"
)
