/// Indicates the field needs to be directly decoded from and encoded to
/// parent `decoder` and `encoder` respectively rather than at a
/// `CodingKey`.
///
/// The `decoder` instance in parent type `Decodable` implementation's
/// `init(from:)` and `encoder` instance in parent type `Encodable`
/// implementation's `encode(to:)` method is directly passed to field type's
/// `init(from:)` and `encode(to:)` method respectively.
///
/// Using this some core `Codable` types can be reused across multiple
/// `Codable` implementations. i.e. for different vehicle types in JSON:
/// ```json
/// [
///   {
///     "id": 5,
///     "name": "Maruti Suzuki Dzire",
///     "type": "Sedan",
///     "brand": "Maruti"
///   },
///   {
///     "id": 105,
///     "name": "Vande Bharat Express",
///     "start": "Delhi",
///     "destination": "Bhopal"
///   }
/// ]
/// ```
/// core `Vehicle` model with common properties can be used with
/// specialized `Car` and `Train` models:
/// ```swift
/// @Codable
/// struct Vehicle {
///     let id: Int
///     let name: String
/// }
///
/// @Codable
/// struct Car {
///     @CodableCompose
///     let base: Vehicle
///     let type: String
///     let brand: String
/// }
///
/// @Codable
/// struct Train {
///     @CodableCompose
///     let base: Vehicle
///     let start: String
///     let destination: String
/// }
/// ```
///
/// - Tip: Use this macro to replace `class`es and inheritance pattern
///      for `Codable` implementation, with composition of `struct`s.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodableCompose() = #externalMacro(
    module: "CodableMacroPlugin",
    type: "CodableFieldMacro"
)

/// Indicates the field needs to be directly decoded from and encoded to
/// parent `decoder` and `encoder` respectively rather than at a
/// `CodingKey`, providing a default value if decoding fails for the field.
///
/// Usage of this macro is the same as base macro ``CodableCompose()``
/// with key difference being able to provide default value similar to
/// ``CodablePath(default:_:)``.
///
/// If decoding the field fails due to some error, default value is used
/// for the field, rather than failing the entire decoding process
/// for parent type.
///
/// - Parameter default: The default value to use in case of decoding failure.
///
/// - Tip: Use this macro to replace `class`es and inheritance pattern
///      for `Codable` implementation, with `struct`s with composition.
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
public macro CodableCompose<T>(
    default: T
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")

/// Indicates the field needs to be directly decoded from and encoded to
/// parent `decoder` and `encoder` (by the provided `helper`)
/// respectively rather than at a `CodingKey`.
///
/// Usage of this macro is the same as base macro ``CodableCompose()``
/// with key difference being able to provide helper instance similar to
/// ``CodablePath(helper:_:)``.
///
/// - Parameter helper: The value that helps for decoding and encoding.
///
/// - Tip: Use this macro to replace `class`es and inheritance pattern
///      for `Codable` implementation, with `struct`s with composition.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s `T.Coded` associated type
///              must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro CodableCompose<T: ExternalHelperCoder>(
    helper: T
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")

/// Indicates the field needs to be directly decoded from and encoded to
/// parent `decoder` and `encoder` (by the provided `helper`)
/// respectively rather than at a `CodingKey`, providing a default value
/// if decoding fails for the field.
///
/// Usage of this macro is the same as base macro ``CodableCompose()``
/// with key difference being able to provide default value and helper instance
/// similar to ``CodablePath(default:helper:_:)``.
///
/// If decoding the field fails due to some error, default value is used
/// for the field, rather than failing the entire decoding process
/// for parent type.
///
/// - Parameters:
///   - default: The default value to use in case of decoding failure.
///   - helper: The value that helps for decoding and encoding.
///
/// - Tip: Use this macro to replace `class`es and inheritance pattern
///      for `Codable` implementation, with `struct`s with composition.
///
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses this
///         macro when generating final implementations.
///
/// - Important: The `helper`'s `T.Coded` associated type
///              must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro CodableCompose<T: ExternalHelperCoder>(
    default: T.Coded,
    helper: T
) = #externalMacro(module: "CodableMacroPlugin", type: "CodableFieldMacro")
