/// Indicates the field/case/type needs to ignored from decoding and encoding.
///
/// This macro can be applied to initialized variables or mutable optional
/// variables to ignore them from both decoding and encoding.
/// ```swift
/// @IgnoreCoding
/// var field: String = "some"
/// ```
///
/// The decoding will succeed even if decoding data doesn't have
/// any `field` key. Even if `field` key is provided in decoding
/// data, value of property `field` will not be impacted. The encoded
/// data will also not have any `field` key.
///
/// Similarly, for enums and protocols this macro can be applied to cases
/// or conforming types respectively to ignore them from both decoding and
/// encoding.
/// ```swift
/// @IgnoreCoding
/// case field(String)
/// ```
/// ```swift
/// @IgnoreCoding
/// struct Load: Command {
///     let key: String
/// }
/// ```
///
/// This case/type will never be decoded or encoded even if decoding data has
/// the data for `field` case or `Load` type respectively.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreCoding() =
    #externalMacro(module: "MacroPlugin", type: "IgnoreCoding")

/// Indicates the field/case/type needs to ignored from decoding.
///
/// This macro can be applied to initialized or optional mutable variables
/// to ignore them from decoding.
/// ```swift
/// @IgnoreDecoding
/// var field: String = "some"
/// ```
///
/// The decoding will succeed even if decoding data doesn't have
/// any `field` key. Even if `field` key is provided in decoding
/// data, value of property `field` will not be impacted. But the
/// encoded data will have `field` key.
///
/// Similarly, for enums and protocols this macro can be applied to cases
/// or conforming types respectively to ignore them from decoding.
/// ```swift
/// @IgnoreDecoding
/// case field(String)
/// ```
/// ```swift
/// @Codable
/// @IgnoreDecoding
/// struct Load: Command, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> { "load" }
///     let key: String
/// }
/// ```
///
/// This case/type will never be decoded even if decoding data has the data for
/// `field` case or `Load` type respectively. But `field` case and `Load`
/// type will be encoded.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreDecoding() =
    #externalMacro(module: "MacroPlugin", type: "IgnoreDecoding")

/// Indicates the field/case/type needs to ignored from encoding.
///
/// This macro can be applied to variables to ignore them from encoding.
/// ```swift
/// @IgnoreEncoding
/// let field: String
/// ```
///
/// The decoding data needs to have applicable data in `field` key.
/// But the encoded data will also not have any `field` key.
///
/// Similarly, for enums and protocols this macro can be applied to cases
/// or conforming types respectively to ignore them from encoding.
/// ```swift
/// @IgnoreEncoding
/// case field(String)
/// ```
/// ```swift
/// @Codable
/// @IgnoreEncoding
/// struct Load: Command, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> { "load" }
///     let key: String
/// }
/// ```
///
/// This case/type will never be encoded. But `field` case and `Load`
/// type will be decoded if case related data is present.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreEncoding() =
    #externalMacro(module: "MacroPlugin", type: "IgnoreEncoding")

/// Indicates the field/case needs to be encoded only if provided condition
/// is not satisfied.
///
/// This macro can be applied to variables to ignore them from encoding.
/// ```swift
/// @IgnoreEncoding(if: \String.isEmpty)
/// let field: String
/// ```
///
/// The decoding data needs to have applicable data in `field` key.
/// But the encoded data might not have any `field` key for specific values
/// if the condition for those values return `true`.
///
/// Similarly, for enums this macro can be applied to cases
/// to ignore them from encoding.
/// ```swift
/// func fieldEncodable(_ str: String) {
///     return !str.isEmpty
/// }
///
/// @IgnoreEncoding(if: fieldEncodable)
/// case field(String)
/// ```
///
/// This case will never be encoded if associated `String` data is empty.
/// But `field` case will be decoded if case related data is present.
///
/// - Parameter condition: The condition to be checked.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The condition argument types must confirm to `Codable`
///   and the single argument should match attached type when attached to field.
///   When attached to cases the arguments count, order and types should match
///   attached enum-case associated variables.
@attached(peer)
@available(swift 5.9)
public macro IgnoreEncoding<each T>(if condition: (repeat each T) -> Bool) =
    #externalMacro(module: "MacroPlugin", type: "IgnoreEncoding")

/// Indicates the field needs to be encoded only if provided condition
/// is not satisfied.
///
/// Provides same functionality as ``IgnoreEncoding(if:)-1iuvv``
/// for fields, provided as separate macro to allow usage in case of
/// Swift parameter packs feature isn't available.
///
/// - Parameter condition: The condition to be checked.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The field type must confirm to `Codable` and
///   default value type `T` must be the same as field type.
@attached(peer)
@available(swift 5.9)
public macro IgnoreEncoding<T>(if condition: (T) -> Bool) =
    #externalMacro(module: "MacroPlugin", type: "IgnoreEncoding")
