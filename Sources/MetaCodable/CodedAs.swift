/// Provides a value to be used for an enum-case instead of using case name.
///
/// When value is provided attached to a case declaration the value is chosen
/// as case value. i.e. for a case declared as:
/// ```swift
/// @CodedAs("loaded")
/// case load(key: Int)
/// ```
/// the encoded JSON for externally tagged enum will be of following format:
/// ```json
/// { "loaded": { "key": 5 } }
/// ```
///
/// - Parameter value: The value to use.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The value type must be `String` when used in
///   externally tagged enums, and internally/adjacently tagged enums
///   without type specified with ``CodedAs()`` macro. When used
///   along with ``CodedAs()`` macro, both the generic type must be same.
@attached(peer)
@available(swift 5.9)
public macro CodedAs<T: Codable & Equatable>(_ value: T) =
    #externalMacro(module: "CodableMacroPlugin", type: "CodedAs")

/// Provides the identifier actual type for internally/adjacently tagged enums.
///
/// When type is provided attached to an enum declaration the identifier is
/// decoded to the provided type instead of `String` type. i.e. for enum:
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
/// the encoded JSON for internally tagged enum will be of following variations:
/// ```json
/// { "key": "MyKey", "type": 1 }
/// ```
/// ```json
/// { "key": "MyKey", "value": 42, "type": 1 }
/// ```
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: For each case ``CodedAs(_:)`` macro with value
///   of the type here should be provided, otherwise case name as `String`
///   will be used for comparison. If the type here conforms to
///   `ExpressibleByStringLiteral` and can be represented by case name
///   as `String` literal then no need to provide value with ``CodedAs(_:)``.
///
/// - Important: This attribute must be used combined with ``Codable()``
///   and ``CodedAt(_:)``.
@attached(peer)
@available(swift 5.9)
public macro CodedAs<T: Codable & Equatable>() =
    #externalMacro(module: "CodableMacroPlugin", type: "CodedAs")
