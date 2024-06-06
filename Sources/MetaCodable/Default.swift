/// Provides a `default` value to be used when decoding fails and
/// when not initialized explicitly in memberwise initializer(s).
///
/// If the value is missing or has incorrect data type, the default value
/// will be used instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @Default("some")
/// let field: String
/// ```
/// if empty json provided or type at `CodingKey` is different
/// ```json
/// { "field": 5 } // or {}
/// ```
/// the default value provided in this case `some` will be used as
/// `field`'s value.
///
/// - Parameter default: The default value to use.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///   default value type `T` must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro Default<T>(_ default: T) =
    #externalMacro(module: "MacroPlugin", type: "Default")

/// Provides a `default` value to be used when value is missing
/// and when not initialized explicitly in memberwise initializer(s).
///
/// If the value is missing , the default value will be used instead of
/// throwing error and terminating decoding. i.e. for a field declared as:
/// ```swift
/// @Default(ifMissing: "some")
/// let field: String
/// ```
/// if empty json provided
/// ```json
/// {}
/// ```
/// the default value provided in this case `some` will be used as
/// `field`'s value.
///
/// - Parameter default: The default value to use.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///   default value type `T` must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro Default<T>(ifMissing default: T) =
    #externalMacro(module: "MacroPlugin", type: "Default")

/// Provides different `default` values to be used for missing value
/// and decoding errors.
///
/// If the value is missing, the `missingDefault` value will be used,
/// while for incorrect data type, `errorDefault` value will be used,
/// instead of throwing error and terminating decoding.
/// i.e. for a field declared as:
/// ```swift
/// @Default(ifMissing: "some", forErrors: "another")
/// let field: String
/// ```
/// if type at `CodingKey` is different or empty json provided
/// ```json
/// { "field": 5 } // or {}
/// ```
/// the default value `some` and `another` will be used as
/// `field`'s value respectively.
///
/// - Parameters:
///   - missingDefault: The default value to use when value is missing.
///   - errorDefault: The default value to use for other errors.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///   default value type `T` must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro Default<T>(
    ifMissing missingDefault: T, forErrors errorDefault: T
) =
    #externalMacro(module: "MacroPlugin", type: "Default")
