/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided.
///
/// * If single argument provided for `path`, then that argument is
///   chosen as `CodingKey`. i.e for JSON:
///   ```json
///   { "key": "value" }
///   ```
///   the field can declare custom key:
///   ```swift
///   @CodedAt("key")
///   let field: String
///   ```
///
/// * If multiple arguments provided, then field is decoded/encoded
///   nested by all the arguments as `CodingKey`. i.e for JSON:
///   ```json
///   { "deeply": { "nested": { "key": "value" } } }
///   ```
///   the field can declare custom key:
///   ```swift
///   @CodedAt("deeply", "nested", "key")
///   let field: String
///   ```
///
/// * If no arguments provided, then field needs to be directly decoded from
///   and encoded to parent `decoder` and `encoder` respectively rather
///   than at a `CodingKey`.
///
///   The `decoder` instance in parent type `Decodable` implementation's
///   `init(from:)` and `encoder` instance in parent type `Encodable`
///   implementation's `encode(to:)` method is directly passed to field type's
///   `init(from:)` and `encode(to:)` method respectively.
///
///   Using this some core `Codable` types can be reused across multiple
///   `Codable` implementations. i.e. for different vehicle types in JSON:
///   ```json
///   [
///     {
///       "id": 5,
///       "name": "Maruti Suzuki Dzire",
///       "type": "Sedan",
///       "brand": "Maruti"
///     },
///     {
///       "id": 105,
///       "name": "Vande Bharat Express",
///       "start": "Delhi",
///       "destination": "Bhopal"
///     }
///   ]
///   ```
///   core `Vehicle` model with common properties can be used with
///   specialized `Car` and `Train` models:
///   ```swift
///   @Codable
///   struct Vehicle {
///       let id: Int
///       let name: String
///   }
///
///   @Codable
///   struct Car {
///       @CodedAt
///       let base: Vehicle
///       let type: String
///       let brand: String
///   }
///
///   @Codable
///   struct Train {
///       @CodedAt
///       let base: Vehicle
///       let start: String
///       let destination: String
///   }
///   ```
///
/// - Parameter path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodedAt(_ path: StaticString...)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided with a `default` value used when
/// decoding fails.
///
/// Usage of `path` argument is the same as in ``CodedAt(_:)``.
/// If no argument is provided as path.
///
/// If the value is missing or has incorrect data type, the default value
/// will be used instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @CodedAt("key", default: "some")
/// let field: String
/// ```
/// if empty json provided or type at `CodingKey` is different
/// ```json
/// { "key": 5 } // or {}
/// ```
/// the default value provided in this case `some` will be used as
/// `field`'s value.
///
/// - Parameters:
///   - path: The `CodingKey` path value located at.
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
public macro CodedAt<T>(_ path: StaticString..., default: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided by the provided `helper` instance.
///
/// Usage of `path` argument is the same as in ``CodedAt(_:)``.
///
/// An instance confirming to ``HelperCoder`` can be provided
/// to allow decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types. i.e ``LossySequenceCoder`` that decodes
/// sequence from JSON ignoring invalid data matches instead of throwing error
/// (failing decoding of entire sequence).
///
/// - Parameters:
///   - path: The `CodingKey` path value located at.
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
public macro CodedAt<T: HelperCoder>(_ path: StaticString..., helper: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")

/// Indicates the field needs to be decoded from and encoded to the
/// `CodingKey` path provided by the provided `helper` instance,
/// with a `default` value used when decoding fails.
///
/// Usage of `path` argument is the same as in ``CodedAt(_:)``.
///
/// Usage of `default` and `helper` arguments are the same as in
/// ``CodedAt(_:default:)`` and
/// ``CodedAt(_:helper:)`` respectively.
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
/// - Important: The `helper`'s ``HelperCoder/Coded``
///              associated type must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro CodedAt<T: HelperCoder>(_ path: StaticString..., default: T.Coded, helper: T)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedPropertyMacro")
