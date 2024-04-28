/// Indicates the cases of enum lack distinct identifier.
///
/// To decode/encode data variations that doesn't have any variation
/// specific identifier, i.e. for JSON:
/// ```json
/// [
///   true, 12, -43, 36.78, "string",
///   [
///     true, 12, -43, 36.78, "string",
///     {
///       "key": "value"
///     }
///   ],
///   {
///     "key": "value"
///   }
/// ]
/// ```
/// following enum can be used:
/// ```swift
/// @Codable
/// @UnTagged
/// enum CodableValue {
///     case bool(Bool)
///     case uint(UInt)
///     case int(Int)
///     case float(Float)
///     case double(Double)
///     case string(String)
///     case array([Self])
///     case dictionary([String: Self])
/// }
/// ```
///
/// When decoding each case associated variables will be tried to be decoded
/// in the order of the case declaration. First case for which all associated
/// variables are successfully decoded, is chosen as the variation case value.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: This macro can only be applied to enums.
@attached(peer)
@available(swift 5.9)
public macro UnTagged() =
    #externalMacro(module: "MacroPlugin", type: "UnTagged")
