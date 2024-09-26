/// Indicates `CodingKey` for the field names/associated value label will be
/// of the provided case format.
///
/// The [Swift API Design Guidelines] recommend using camel-case names.
/// This macro can be used for types to work with `CodingKey`s of different
/// case format while keeping variable names camel-cased.
///
/// For a JSON where keys follow snake-case style:
/// ```json
/// {
///   "product_name": "Banana",
///   "product_cost": 200,
///   "description": "A banana grown in Ecuador."
/// }
/// ```
///
/// equivalent `Codable` type can be created that uses keys in camel-case
/// style:
/// ```swift
/// @Codable
/// @CodingKeys(.snake_case)
/// struct CodableType {
///     let productName: String
///     let productCost: String
///     let description: String
/// }
/// ```
/// The ``Codable()`` macro generated code will transform field names
/// to snake-case in the `Codable` implementation.
///
/// Similarly, for enums associated value label can be kept camel-cased while
/// `CodingKey`s of different case style can be generated.
///
/// For a JSON where keys follow snake-case style:
/// ```json
/// {
///   "banana": {
///     "product_cost": 200
///   },
///   "apple": {
///     "product_cost": 200
///   }
/// }
/// ```
///
/// equivalent `Codable` type can be created that uses keys in camel-case
/// style:
/// ```swift
/// @Codable
/// @CodingKeys(.snake_case)
/// enum CodableType {
///     case banana(_ productCost: String)
///     case apple(_ productCost: String)
/// }
/// ```
///
/// Also, for enums `CodingKey`s of different case styles can be generated
/// per case while keeping all associated values label camel-cased.
///
/// For a JSON where keys follow mixed snake-case and kebab-case style:
/// ```json
/// {
///   "banana": {
///     "product_cost": 200
///   },
///   "apple": {
///     "product-cost": 200
///   }
/// }
/// ```
///
/// equivalent `Codable` type can be created that uses keys in camel-case
/// style:
/// ```swift
/// @Codable
/// enum CodableType {
///     @CodingKeys(.snake_case)
///     case banana(_ productCost: String)
///     @CodingKeys(.kebab－case)
///     case apple(_ productCost: String)
/// }
/// ```
///
/// - Parameter strategy: The case strategy `CodingKey`.
///
/// - Note: The case strategy is only used to transform field names to
///   `CodingKey`s. `CodingKey`s provided with ``CodedIn(_:)``,
///   ``CodedAt(_:)`` will remain unchanged.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: This attribute must be used combined with ``Codable()``.
///
/// [Swift API Design Guidelines]:
/// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
@attached(peer)
@available(swift 5.9)
public macro CodingKeys(_ strategy: CodingKeyNameStrategy) =
    #externalMacro(module: "MacroPlugin", type: "CodingKeys")

/// The values that determine the equivalent
/// `CodingKey` value for a property name.
///
/// Property names are transformed into string
/// value based on the case strategy to be used
/// as `CodingKey`.
public enum CodingKeyNameStrategy: Sendable {
    /// A strategy that converts property names to camel-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This is not needed typically unless some other case style is being used
    /// for property names and to work with camel-cased keys.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Keep the first word lowercased, while capitalizing first letter of rest.
    /// 1. Join all the words without any joining separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `FeeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `feeFiFoFum`
    ///
    /// `fee_fi_fo_fum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `feeFiFoFum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case camelCase
    /// A strategy that converts property names to pascal-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with pascal-cased keys while keeping
    /// variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Capitalize first letter of all the words.
    /// 1. Join all the words without any joining separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FeeFiFoFum`
    ///
    /// `FeeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FeeFiFoFum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case PascalCase
    /// A strategy that converts property names to snake-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with snake-cased keys while keeping
    /// variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Convert all the words to lowercase.
    /// 1. Join all the words with `_` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee_fi_fo_fum`
    ///
    /// `fee_fi_fo_fum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee_fi_fo_fum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case snake_case
    /// A strategy that converts property names to camel-cased snake-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with camel-cased snake-case keys
    /// while keeping variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Keep the first word lowercased, while capitalizing first letter of rest.
    /// 1. Join all the words with `_` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee_Fi_Fo_Fum`
    ///
    /// `fee_Fi_Fo_Fum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee_Fi_Fo_Fum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case camel_Snake_Case
    /// A strategy that converts property names to uppercased snake-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with uppercased snake-case keys while
    /// keeping variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Convert all the words to uppercase.
    /// 1. Join all the words with `_` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FEE_FI_FO_FUM`
    ///
    /// `FEE_FI_FO_FUM`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FEE_FI_FO_FUM`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case SCREAMING_SNAKE_CASE
    /// A strategy that converts property names to kebab-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with kebab-cased keys while keeping
    /// variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Convert all the words to lowercase.
    /// 1. Join all the words with `-` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee-fi-fo-fum`
    ///
    /// `fee-fi-fo-fum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `fee-fi-fo-fum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case kebab－case
    /// A strategy that converts property names to uppercased kebab-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with uppercased kebab-case keys while
    /// keeping variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Convert all the words to uppercase.
    /// 1. Join all the words with `-` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FEE-FI-FO-FUM`
    ///
    /// `FEE-FI-FO-FUM`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `FEE-FI-FO-FUM`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case SCREAMING－KEBAB－CASE
    /// A strategy that converts property names to title-cased kebab-case keys.
    ///
    /// The [Swift API Design Guidelines] recommend using camel-case names.
    /// This strategy can be used to work with title-cased kebab-case keys while
    /// keeping variable names camel-cased.
    ///
    /// This strategy uses `uppercaseLetters`, `lowercaseLetters`
    /// and non-`alphanumerics` to determine the boundaries between words.
    ///
    /// This strategy follows these steps to convert key names to camel-case:
    /// 1. Split the name into words, removing special characters.
    /// 1. Capitalize first letter of all the words.
    /// 1. Join all the words with `-` separator.
    ///
    /// Following are the results when applying this strategy:
    ///
    /// `feeFiFoFum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `Fee-Fi-Fo-Fum`
    ///
    /// `Fee-Fi-Fo-Fum`\
    /// &nbsp;&nbsp;&nbsp;&nbsp; Converts to: `Fee-Fi-Fo-Fum`
    ///
    /// [Swift API Design Guidelines]:
    /// https://www.swift.org/documentation/api-design-guidelines/#general-conventions
    case Train－Case
}
