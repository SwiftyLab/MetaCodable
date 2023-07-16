/// Indicates the field needs to be decoded from and encoded in the
/// container `CodingKey` path provided with field name as final
/// `CodingKey`.
///
/// This macro behaves similar to ``CodedAt(_:)`` with adding
/// the field name to the end of `CodingKey` path
///
/// * If no argument provided for `path`, then the field name is chosen
///   as `CodingKey` in the current type's container. i.e for JSON:
///   ```json
///   { "field": "value" }
///   ```
///   the field can be declared as:
///   ```swift
///   @CodedIn
///   let field: String
///   ```
///
/// * If one or more arguments are provided, then field is decoded/encoded
///   nested by all the arguments as `CodingKey` and the field name
///   as final `CodingKey`. i.e for JSON:
///   ```json
///   { "deeply": { "nested": { "field": "value" } } }
///   ```
///   the field can declare custom key:
///   ```swift
///   @CodedIn("deeply", "nested")
///   let field: String
///   ```
///
/// - Parameter path: The `CodingKey` path of container value located in.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Note: Providing no arguments has the same effect as not applying
///         the macro entirely. Warning is generated with diagnostic id
///         `codedin-unused` in such case to either remove
///         attribute or provide arguments.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodedIn(_ path: StaticString...)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded in the
/// container `CodingKey` path provided with field name as final
/// `CodingKey`, provided with a `default` value used when
/// decoding fails.
///
/// Usage of `path` argument is the same as in ``CodedIn(_:)``.
///
/// If the value is missing or has incorrect data type, the default value
/// will be used instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @CodedIn(default: "some")
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
///   - path: The `CodingKey` path of container value located in.
///   - default: The default value to use in case of decoding failure.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///              default value type `T` must be the same as
///              field type.
@attached(peer)
@available(swift 5.9)
public macro CodedIn<T>(_ path: StaticString..., default: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded in the
/// container `CodingKey` path provided with field name as final
/// `CodingKey`, provided by the provided `helper` instance.
///
/// Usage of `path` argument is the same as in ``CodedIn(_:)``.
///
/// An instance confirming to ``HelperCoder`` can be provided
/// to allow decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types. i.e ``LossySequenceCoder`` that decodes
/// sequence from JSON ignoring invalid data matches instead of throwing error
/// (failing decoding of entire sequence).
///
/// - Parameters:
///   - path: The `CodingKey` path of container value located in.
///   - helper: The value that helps for decoding and encoding.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s ``HelperCoder/Coded``
///              associated type must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro CodedIn<T: HelperCoder>(_ path: StaticString..., helper: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded in the
/// container `CodingKey` path provided with field name as final
/// `CodingKey`, provided by the provided `helper` instance,
/// with a `default` value used when decoding fails.
///
/// Usage of `path` argument is the same as in ``CodedIn(_:)``.
///
/// Usage of `default` and `helper` arguments are the same as in
/// ``CodedIn(_:default:)`` and
/// ``CodedIn(_:helper:)`` respectively.
///
/// - Parameters:
///   - path: The `CodingKey` path of container value located in.
///   - default: The default value to use in case of decoding failure.
///   - helper: The value that helps for decoding and encoding.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s ``HelperCoder/Coded``
///              associated type must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro CodedIn<T: HelperCoder>(_ path: StaticString..., default: T.Coded, helper: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")
