/// Indicates the field/case/type needs to ignored from decoding and encoding.
///
/// This macro can be applied to initialized variables to ignore them
/// from both decoding and encoding.
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
/// This macro can be applied to initialized mutable variables to ignore
/// them from decoding.
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
