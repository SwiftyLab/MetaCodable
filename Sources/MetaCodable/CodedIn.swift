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
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Note: Providing no arguments has the same effect as not applying
///   the macro entirely. Warning is generated with diagnostic id
///   `codedin-unused` in such case to either remove attribute or
///   provide arguments.
///
/// - Important: The field type must confirm to `Codable`.
@attached(peer)
@available(swift 5.9)
public macro CodedIn(_ path: StaticString...) =
    #externalMacro(module: "MacroPlugin", type: "CodedIn")
