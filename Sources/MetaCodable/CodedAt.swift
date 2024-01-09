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
/// * For enums/protocols, this attribute can be used to support internally
///   tagged data. The `CodingKey` path provided represents the path
///   where value identifying each case/conforming type respectively is
///   decoded/encoded. By default, this value is decoded/encoded as
///   `String` unless different type specified with ``CodedAs()`` and
///   compared with value for each enum-case identifier or conformed type
///   ``DynamicCodable/identifier``. i.e. for enum:
///   ```swift
///   @Codable
///   @CodedAt("type")
///   enum Command {
///       case load(key: String)
///       case store(key: String, value: Int)
///   }
///   ```
///   or protocol:
///   ```swift
///   @Codable
///   @CodedAt("type")
///   @CodedAs<Int>
///   protocol Command {
///       var key: String { get }
///   }
///
///   @Codable
///   struct Load: Command, DynamicCodable {
///       static var identifier: DynamicCodableIdentifier<String> { "load" }
///       let key: String
///   }
///
///   @Codable
///   struct Store: Command, DynamicCodable {
///       static var identifier: DynamicCodableIdentifier<String> { "store" }
///       let key: String
///       let value: Int
///   }
///   ```
///   the encoded JSON for internally tagged data will be of following variations:
///   ```json
///   { "key": "MyKey", "type": "load" }
///   ```
///   ```json
///   { "key": "MyKey", "value": 42, "type": "store" }
///   ```
///
/// - Parameter path: The `CodingKey` path value located at.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: When applied to fields, the field type must confirm to
///   `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodedAt(_ path: StaticString...) =
    #externalMacro(module: "MacroPlugin", type: "CodedAt")
