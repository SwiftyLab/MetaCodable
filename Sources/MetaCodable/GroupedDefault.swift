/// Provides a `GroupedDefault` value to be used when decoding fails and
/// when not initialized explicitly in memberwise initializer(s).
///
/// If the value is missing or has incorrect data type, the default value
/// will be used instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @GroupedDefault("some", 10)
/// let field: String, field2: Int
/// ```
/// if empty json provided or type at `CodingKey` is different
/// ```json
/// { "field": 5 } // or {}
/// ```
/// the default value provided in this case `some` will be used as
/// `field`'s value.
///
/// - Parameter defaults: The defaults value to use.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///   default value type `T` must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro GroupedDefault<each T>(_ defaults: repeat each T) =
    #externalMacro(module: "MacroPlugin", type: "GroupedDefault")
