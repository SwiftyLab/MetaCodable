/// Indicates by default initialized properties/associated values for
/// the attached type/enum-case will be ignored for decoding/encoding.
///
/// This macro can be applied to types to ignore decoding and encoding
/// all initialized properties of said type:
/// ```swift
/// @Codable
/// @IgnoreCodingInitialized
/// struct CodableType {
///     var initialized: String = "some"
///     let field: String
/// }
/// ```
/// Here `initialized` property is ignored from decoding and encoding
/// while `field` is decoded and encoded.
///
/// Initialized properties can explicitly considered for decoding and encoding
/// by attaching any coding attributes, i.e. ``CodedIn(_:)``, ``CodedAt(_:)``,
/// ``CodedBy(_:)``, ``Default(_:)`` etc.
/// ```swift
/// @Codable
/// @IgnoreCodingInitialized
/// struct CodableType {
///     var initialized: String = "some"
///     @CodedIn
///     var explicitCode: String = "coded"
///     let field: String
/// }
/// ```
/// Here `explicitCode` property is decoded and encoded
/// while `initialized` is ignored from decoding and encoding.
///
/// Similarly, all initialized associated values can be ignored for decoding
/// and encoding in enum type:
/// ```swift
/// @Codable
/// @IgnoreCodingInitialized
/// enum CodableType {
///     case one(initialized: String = "some")
///     case two(uninitialized: String)
/// }
/// ```
/// Here `initialized` associated value is ignored from decoding and encoding
/// while `uninitialized` is decoded and encoded.
///
/// Also, only for particular case initialized associated values can be ignored
/// for decoding and encoding in enum type:
/// ```swift
/// @Codable
/// enum CodableType {
///     @IgnoreCodingInitialized
///     case one(initialized: String = "some")
///     case two(notIgnored: String = "some")
/// }
/// ```
/// Here `initialized` associated value is ignored from decoding and encoding
/// while `notIgnored` is decoded and encoded.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: This attribute must be used combined with ``Codable()``.
@attached(peer)
@available(swift 5.9)
public macro IgnoreCodingInitialized() =
    #externalMacro(module: "MacroPlugin", type: "IgnoreCodingInitialized")
