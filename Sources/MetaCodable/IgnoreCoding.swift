/// Indicates the field needs to ignored from decoding and encoding.
///
/// This macro can be applied to initialized mutable variables to ignore
/// them from both decoding and encoding.
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
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses
///         this macro when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreCoding()
= #externalMacro(module: "CodableMacroPlugin", type: "IgnoreCoding")

/// Indicates the field needs to ignored from decoding.
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
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses
///         this macro when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreDecoding()
= #externalMacro(module: "CodableMacroPlugin", type: "IgnoreDecoding")

/// Indicates the field needs to ignored from encoding.
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
/// - Note: This macro on its own only validates if attached declaration
///         is a variable declaration. ``Codable()`` macro uses
///         this macro when generating final implementations.
@attached(peer)
@available(swift 5.9)
public macro IgnoreEncoding()
= #externalMacro(module: "CodableMacroPlugin", type: "IgnoreEncoding")
