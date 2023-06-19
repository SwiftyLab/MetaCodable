/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided.
///
/// If single argument provided for `path`, then that argument is
/// chosen as `CodingKey`. i.e for JSON:
/// ```json
/// { "key": "value" }
/// ```
/// the field can declare custom key:
/// ```swift
/// @CodablePath("key")
/// let field: String
/// ```
///
/// If multiple arguments are provided, then field is decoded/encoded
/// nested by all the arguments as `CodingKey`. i.e for JSON:
/// ```json
/// { "deeply": { "nested": { "key": "value" } } }
/// ```
/// the field can declare custom key:
/// ```swift
/// @CodablePath("deeply", "nested", "key")
/// let field: String
/// ```
///
/// - Parameter path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Note: Providing no arguments has the same effect as not applying
///         the macro entirely. Warning is generated with diagnostic id
///         `codablepath-unused` in such case to either remove
///         attribute or provide arguments.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
public macro CodablePath(
    _ path: StaticString...
) = #externalMacro(
    module: "CodableMacroPlugin",
    type: "CodableFieldMacro"
)

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided with a `default` value used when
/// decoding fails.
///
/// Usage of `path` argument is the same as in ``CodablePath(_:)``.
/// If no argument is provided as path, field name is used as
/// `CodingKey`.
///
/// If the value is missing or has incorrect data type, the default value
/// will be used instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @CodablePath(default: "some")
/// let field: String
/// ```
/// if empty json provided or type at `CodingKey` is different
/// ```json
/// { "field": 5 } // or {}
/// ```
/// the default value provided in this case `some` will be used as
/// `field`'s value.
///
/// - Parameters:
///   - default: The default value to use in case of decoding failure.
///   - path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///              default value type `T` must be the same as
///              field type.
@attached(peer)
public macro CodablePath<T>(
    default: T,
    _ path: StaticString...
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided by the provided `helper` instance.
///
/// Usage of `path` argument is the same as in ``CodablePath(_:)``.
/// If no argument is provided as path, field name is used as `CodingKey`.
///
/// An instance confirming to ``ExternalHelperCoder`` can be provided
/// to allow decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types. i.e ``LossySequenceCoder`` that decodes
/// sequence from JSON ignoring invalid data matches instead of throwing error
/// (failing decoding of entire sequence).
///
/// - Parameters:
///   - helper: The value that helps for decoding and encoding.
///   - path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s `T.Coded` associated type
///              must be the same as field type.
@attached(peer)
public macro CodablePath<T: ExternalHelperCoder>(
    helper: T,
    _ path: StaticString...
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided by the provided `helper` instance,
/// with a `default` value used when decoding fails.
///
/// Usage of `path` argument is the same as in ``CodablePath(_:)``.
/// If no argument is provided as path, field name is used as `CodingKey`.
///
/// Usage of `default` and `helper` arguments are the same as in
/// ``CodablePath(default:_:)`` and
/// ``CodablePath(helper:_:)`` respectively.
///
/// - Parameters:
///   - default: The default value to use in case of decoding failure.
///   - helper: The value that helps for decoding and encoding.
///   - path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s `T.Coded` associated type
///              must be the same as field type.
@attached(peer)
public macro CodablePath<T: ExternalHelperCoder>(
    default: T.Coded,
    helper: T,
    _ path: StaticString...
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")
