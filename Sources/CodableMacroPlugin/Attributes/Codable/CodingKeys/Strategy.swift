import SwiftSyntax

extension CodingKeys {
    /// The values that determine the equivalent
    /// `CodingKey` value for a property name.
    ///
    /// Property names are transformed into string
    /// value based on the case strategy to be used
    /// as `CodingKey`.
    enum Strategy: String, CaseIterable {
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

        /// Parses case strategy from provided expression.
        ///
        /// Checks the strategy provided to the `CodingKeys`
        /// macro.
        ///
        /// - Parameter expr: The strategy expression syntax.
        /// - Returns: Parsed case strategy.
        init(with expr: ExprSyntax) {
            let description = expr.trimmed.description
            for `case` in Self.allCases {
                guard description.hasSuffix(`case`.rawValue) else { continue }
                self = `case`
                return
            }
            self = .camelCase
        }

        /// Transform provided `CodingKey` path string according
        /// to current strategy.
        ///
        /// Adjusts elements in provided `CodingKey` path to match
        /// the current casing style.
        ///
        /// - Parameter keyPath: The `CodingKey` path to transform.
        /// - Returns: The transformed `CodingKey` path.
        func transform(keyPath: [String]) -> [String] {
            let transformer = CodingKeyTransformer(strategy: self)
            return keyPath.map { transformer.transform(key: $0) }
        }
    }
}
