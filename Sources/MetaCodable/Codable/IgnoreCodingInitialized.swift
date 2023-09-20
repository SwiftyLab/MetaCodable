/// Indicates by default initialized properties for the attached type will be
/// ignored for decoding/encoding.
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
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: This attribute must be used combined with ``Codable()``.
@attached(peer)
@available(swift 5.9)
public macro IgnoreCodingInitialized() =
    #externalMacro(
        module: "CodableMacroPlugin", type: "IgnoreCodingInitialized"
    )
