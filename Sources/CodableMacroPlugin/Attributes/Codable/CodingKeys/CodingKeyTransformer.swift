@_implementationOnly import Foundation

/// A type performing transformation on provided `CodingKey`.
///
/// Performs transformation on provided `CodingKey`
/// based on the strategy passed during initialization.
/// The separation letter and separated words capitalization
/// style is adjusted according to the provided case style.
struct CodingKeyTransformer {
    /// The key transformation strategy provided.
    let strategy: CodingKeys.Strategy

    /// Transform provided `CodingKey` string according
    /// to current strategy.
    ///
    /// Adjusts elements in provided `CodingKey` to match
    /// the current casing strategy.
    ///
    /// - Parameter key: The `CodingKey` to transform.
    /// - Returns: The transformed `CodingKey`.
    func transform(key: String) -> String {
        guard !key.isEmpty else { return key }

        let interimKey: String
        if #available(macOS 13, iOS 16, macCatalyst 16, tvOS 16, watchOS 9, *) {
            let regex = #/([a-z0-9])([A-Z])/#
            interimKey = key.replacing(regex) { match in
                let (_, first, second) = match.output
                return "\(first)@\(second)"
            }.lowercased()
        } else {
            let regex = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])")
            let range = NSRange(location: 0, length: key.count)
            interimKey = regex.stringByReplacingMatches(
                in: key,
                range: range,
                withTemplate: "$1@$2"
            ).lowercased()
        }

        let parts = interimKey.components(separatedBy: .alphanumerics.inverted)
        return strategy.capitalization
            .transform(parts: parts)
            .joined(separator: strategy.separator)
    }
}

fileprivate extension CodingKeys.Strategy {
    /// The separator being used by current case style.
    ///
    /// There might not be any separator for current case style,
    /// in such case empty string is returned. Otherwise the separator
    /// character corresponding to current case is returned.
    var separator: String {
        switch self {
        case .camelCase, .PascalCase:
            return ""
        case .snake_case, .camel_Snake_Case, .SCREAMING_SNAKE_CASE:
            return "_"
        case .kebab－case, .Train－Case, .SCREAMING－KEBAB－CASE:
            return "-"
        }
    }
}

fileprivate extension CodingKeys.Strategy {
    /// Represents capitalization style
    /// of each token in a casing style.
    ///
    /// Indicates capitalization style preferred
    /// by each separated word in a casing style,
    /// i.e. upper, lower, only first letter is capitalized etc.
    enum Capitalization {
        /// Represents all the separated
        /// words are in upper case.
        ///
        /// Typically used for screaming
        /// style cases with separators.
        case upper
        /// Represents all the separated words
        /// have only first letter capitalized.
        ///
        /// Typically used for default
        /// style cases with separators.
        case lower
        /// Represents all the separated
        /// words are in lower case.
        ///
        /// Typically used for default
        /// style cases with separators.
        case all
        /// Represents first word is in lower case
        /// and subsequent words have only
        /// first letter capitalized.
        ///
        /// Typically used for styles that are variation
        /// on top of default styles.
        case exceptFirst

        /// Converts provided string tokens according
        /// to current casing style.
        ///
        /// Adjusts capitalization style of provided string tokens
        /// according to current casing style.
        ///
        /// - Parameter parts: The string tokens to transform.
        /// - Returns: The transformed string tokens.
        func transform(parts: [String]) -> [String] {
            guard !parts.isEmpty else { return parts }
            switch self {
            case .upper:
                return parts.map { $0.uppercased() }
            case .lower:
                return parts.map { $0.lowercased() }
            case .all:
                return parts.map { $0.uppercasingFirst }
            case .exceptFirst:
                let first = parts.first!.lowercasingFirst
                let rest = parts.dropFirst().map { $0.uppercasingFirst }
                return [first] + rest
            }
        }
    }

    /// The capitalization casing style of each pattern
    /// corresponding to current strategy.
    ///
    /// Depending on the current style it might be upper,
    /// lower or capitalizing first word etc.
    var capitalization: Capitalization {
        switch self {
        case .camelCase, .camel_Snake_Case:
            return .exceptFirst
        case .snake_case, .kebab－case:
            return .lower
        case .SCREAMING_SNAKE_CASE, .SCREAMING－KEBAB－CASE:
            return .upper
        case .PascalCase, .Train－Case:
            return .all
        }
    }
}

/// Helps converting any string to camel case
///
/// Picked up from:
/// https://gist.github.com/reitzig/67b41e75176ddfd432cb09392a270218
extension String {
    /// Makes the first letter lowercase.
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    /// Makes the first letter uppercase.
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }

    /// Convert any string to camel case
    ///
    /// Removes non-alphanumeric characters
    /// and makes the letters just after these
    /// characters uppercase.
    ///
    /// First letter is made lowercase.
    var camelCased: String {
        return CodingKeyTransformer(strategy: .camelCase).transform(key: self)
    }

    /// Check if begins with number.
    ///
    /// Checks whether key name begins with number.
    var beginsWithNumber: Bool {
        if #available(macOS 13, iOS 16, macCatalyst 16, tvOS 16, watchOS 9, *) {
            return try! #/^[0-9]+[a-zA-Z0-9]*/#.wholeMatch(in: self) != nil
        } else {
            return self.range(
                of: "^[0-9]+[a-zA-Z0-9]*",
                options: .regularExpression
            ) != nil
        }
    }
}
