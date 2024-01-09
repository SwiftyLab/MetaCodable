/// Provides values to be used for an enum-case instead of using case name or
/// additional variable `CodingKey`s.
///
/// * When values are provided attached to a case declaration those are chosen
///   as case values. The case can be decoded from any of the value specified
///   while only first value is used for encoding. i.e. for a case declared as:
///   ```swift
///   @CodedAs("loaded", "operation_loaded")
///   case load(key: Int)
///   ```
///   can be decoded from both the externally tagged JSON:
///   ```json
///   { "loaded": { "key": 5 } }
///   ```
///   or
///   ```json
///   { "operation_loaded": { "key": 5 } }
///   ```
///   but when encoding only first JSON will be generated.
///
/// * When attached to variables, the values are chosen additional `CodingKey`s
///   the variable data might appear at. Only the primary key specified with
///   ``CodedAt(_:)`` or the variable name is used when encoding. i.e. for a
///   variable declared as:
///   ```swift
///   @CodedAt("key")
///   @CodedAs("key_field")
///   let field: String
///   ```
///   can be decoded from both the JSON:
///   ```json
///   { "key": "value" }
///   ```
///   or
///   ```json
///   { "key_field": "value" }
///   ```
///   but when encoding only first JSON will be generated.
///
/// - Parameter values: The values to use.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The value type must be `String` when used in
///   externally tagged enums or variables, and internally/adjacently tagged
///   enums without type specified with ``CodedAs()`` macro. When used
///   along with ``CodedAs()`` macro, both the generic type must be same.
///
/// - Important: For externally tagged enum-cases and variables, data
///   must have only one of the key present, otherwise decoding will result in
///   `DecodingError.typeMismatch` error.
@attached(peer)
@available(swift 5.9)
public macro CodedAs<T: Codable & Equatable>(_ values: T, _: T...) =
    #externalMacro(module: "MacroPlugin", type: "CodedAs")

/// Provides the identifier actual type for internally/adjacently tagged enums
/// and protocols.
///
/// When type is provided attached to enum/protocol declaration the identifier
/// is decoded to the provided type instead of `String` type. i.e. for enum:
/// ```swift
/// @Codable
/// @CodedAt("type")
/// @CodedAs<Int>
/// enum Command {
///     @CodedAs(1)
///     case load(key: String)
///     @CodedAs(2)
///     case store(key: String, value: Int)
/// }
/// ```
/// or protocol:
/// ```swift
/// @Codable
/// @CodedAt("type")
/// @CodedAs<Int>
/// protocol Command {
///     var key: String { get }
/// }
///
/// @Codable
/// struct Load: Command, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<Int> { 1 }
///     let key: String
/// }
///
/// @Codable
/// struct Store: Command, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<Int> { 2 }
///     let key: String
///     let value: Int
/// }
/// ```
/// the encoded JSON for internally tagged data will be of following variations:
/// ```json
/// { "key": "MyKey", "type": 1 }
/// ```
/// ```json
/// { "key": "MyKey", "value": 42, "type": 2 }
/// ```
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: For each case ``CodedAs(_:_:)`` macro with values
///   of the type here should be provided, otherwise case name as `String`
///   will be used for comparison. If the type here conforms to
///   `ExpressibleByStringLiteral` and can be represented by case name
///   as `String` literal then no need to provide values with ``CodedAs(_:_:)``.
///
/// - Important: When using with protocols ``DynamicCodable/IdentifierValue``
///   type must be same as the type defined with this macro, in absence of this macro
///   ``DynamicCodable/IdentifierValue`` type must be `String`.
///
/// - Important: This attribute must be used combined with ``Codable()``
///   and ``CodedAt(_:)``.
@attached(peer)
@available(swift 5.9)
public macro CodedAs<T: Codable & Equatable>() =
    #externalMacro(module: "MacroPlugin", type: "CodedAs")
