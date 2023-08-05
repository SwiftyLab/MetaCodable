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
///         is a variable declaration. ``Codable()`` macro uses
///         this macro when generating final implementations.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodedAt(_ path: StaticString...)
= #externalMacro(module: "CodableMacroPlugin", type: "CodedAt")
