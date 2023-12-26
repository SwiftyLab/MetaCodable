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
///   externally tagged enums.
@attached(peer)
@available(swift 5.9)
public macro CodedAs<T: Codable>(_ value: T) =
    #externalMacro(module: "CodableMacroPlugin", type: "CodedAs")
