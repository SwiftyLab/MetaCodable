import SwiftSyntax
import SwiftSyntaxMacros
import OrderedCollections

extension Registrar {
    /// A map containing all the case names
    /// for keys in a particular type.
    ///
    /// This map avoids conflicting case names
    /// for similar sounding keys and duplicate
    /// case definitions for keys declared
    /// multiple times.
    final class CaseMap {
        /// A type indicating how the
        /// case name was decided.
        ///
        /// Helps `CaseMap` decide
        /// how to handle conflicting
        /// key values.
        enum Case {
            /// The case name was picked up
            /// directly from field name.
            ///
            /// This case name type can override
            /// other case name types.
            case field(TokenSyntax)
            /// The case name was picked up
            /// directly from field name that is decoded/encoded
            /// at nested `CodingKey` path.
            ///
            /// This case name type can override
            /// `builtWithKey` case name type.
            case nestedKeyField(TokenSyntax)
            /// The case name was picked up
            /// directly from key value.
            ///
            /// Instead of direct usage of key string
            /// `CaseMap.add(forKeys:field:context:)`
            /// method applies some processors to build case name.
            case builtWithKey(TokenSyntax)

            /// The actual case name token syntax.
            var token: TokenSyntax {
                switch self {
                case .field(let token), .nestedKeyField(let token),
                    .builtWithKey(let token):
                    return token
                }
            }

            /// The actual case name
            /// token syntax as a string.
            var name: String {
                switch self {
                case .field(let token), .nestedKeyField(let token),
                    .builtWithKey(let token):
                    return token.text
                }
            }
        }

        /// Generated enum type name.
        let typeName: TokenSyntax = "CodingKeys"
        /// Generated enum type expression that can be passed
        /// to functions as parameter.
        var type: ExprSyntax { "\(typeName).self" }
        /// The key and associated
        /// case name syntax map.
        ///
        /// Kept up-to-date by
        /// `add(forKeys:field:context:)`
        /// method.
        private var data: OrderedDictionary<String, Case> = [:]

        /// Generates case names for provided keys
        /// using the associated `field` and
        /// macro expansion `context`.
        ///
        /// Following rules followed for generating case name:
        /// * For last key in `keys` list, if no associated case found,
        ///   or associated case is of type `builtWithKey` then
        ///   field name passed overrides the case name.
        /// * If only one key present in `keys` list, and associated case
        ///   is of type `nestedKeyField` then field name passed
        ///   overrides the case name as well.
        /// * For last key in `keys` list, if associated case is of type `field`
        ///   or `nestedKeyField` with more than one `keys`
        ///   then case name is kept as it is.
        /// * For other keys, case name is constructed from key string
        ///   after formatting with these rules:
        ///     * Convert key to camelcase
        ///     * If after conversion, string begins with numbers,
        ///       `key` is prepended
        ///     * If current cases in the `CaseMap` doesn't contain built string,
        ///       and built string doesn't conflict with existing Swift keywords
        ///       in `invalidCaseNames` then built string added as
        ///       case name for the key.
        ///     * If built string is already present as case name,
        ///       `MacroExpansionContext.makeUniqueName`
        ///       used to create unique case name with the built string
        ///       as input.
        ///     * If built string is already conflicts with
        ///       Swift keywords in `invalidCaseNames`,
        ///       then built string is wrapped with \` and checked
        ///       if present in current cases in the `CaseMap`.
        ///       If not present new string added as case name,
        ///       otherwise previous rule is used.
        ///
        /// - Parameters:
        ///   - keys: The `CodingKey`s path for the field's value.
        ///   - field: The field located at the `CodingKey` path.
        ///   - context: The macro expansion context.
        func add(
            forKeys keys: [String] = [],
            field: TokenSyntax,
            context: some MacroExpansionContext
        ) {
            guard !keys.isEmpty else { return }
            switch data[keys.last!] {
            case .none, .builtWithKey:
                guard keys.count > 1 else { fallthrough }
                data[keys.last!] = .nestedKeyField(field)
            case .nestedKeyField where keys.count == 1:
                data[keys.last!] = .field(field)
            default:
                break
            }

            for key in keys.dropLast() where data[key] == nil {
                var fieldName = key.camelCased
                let shouldAddKey: Bool
                if #available(
                    macOS 13, iOS 16, macCatalyst 16,
                    tvOS 16, watchOS 9, *
                ) {
                    shouldAddKey = try! #/^[0-9]+[a-zA-Z0-9]*/#
                        .wholeMatch(in: fieldName) != nil
                } else {
                    shouldAddKey =
                        fieldName.range(
                            of: "^[0-9]+[a-zA-Z0-9]*",
                            options: .regularExpression
                        ) != nil
                }
                if shouldAddKey { fieldName = "key\(fieldName)" }

                let currentCases = data.values.map(\.name)
                data[key] = {
                    if !currentCases.contains(fieldName) && !fieldName.isEmpty {
                        if !invalidCaseNames.contains(fieldName) {
                            return .builtWithKey(.identifier(fieldName))
                        } else if !currentCases.contains("`\(fieldName)`") {
                            return .builtWithKey(.identifier("`\(fieldName)`"))
                        }
                    }
                    return .builtWithKey(context.makeUniqueName(fieldName))
                }()
            }
        }

        /// The case name token syntax available for a key.
        ///
        /// - Parameter key: The key to look up against.
        /// - Returns: The token syntax for case name stored against
        ///            a key if exists. Otherwise `nil` returned.
        ///
        /// - Note: Should only be used after case names generated
        ///         for all the keys for a particular type.
        func `case`(forKey key: String) -> TokenSyntax? {
            return data[key]?.token
        }

        /// Creates an enum declaration from the current maps of cases
        /// and key values.
        ///
        /// The generated enum is a raw enum of `String` type
        /// and confirms to `CodingKey`.
        ///
        /// - Parameter context: The macro expansion context.
        /// - Returns: The generated enum declaration syntax.
        func decl(in context: some MacroExpansionContext) -> EnumDeclSyntax {
            let clause = TypeInheritanceClauseSyntax {
                InheritedTypeSyntax(typeName: "String" as TypeSyntax)
                InheritedTypeSyntax(typeName: "CodingKey" as TypeSyntax)
            }
            return EnumDeclSyntax(
                identifier: typeName,
                inheritanceClause: clause
            ) {
                for (key, `case`) in data {
                    "case \(`case`.token) = \(literal: key)" as DeclSyntax
                }
            }
        }
    }
}

/// Helps converting any string to camel case
///
/// Picked up from:
/// https://gist.github.com/reitzig/67b41e75176ddfd432cb09392a270218
fileprivate extension String {
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
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.lowercasingFirst
        let rest = parts.dropFirst().map { $0.uppercasingFirst }
        return ([first] + rest).joined()
    }
}

/// Case names that can conflict with Swift keywords and cause build error.
///
/// Picked up by filtering:
/// https://github.com/apple/swift-syntax/blob/main/Sources/SwiftSyntax/generated/Keyword.swift#L764
private let invalidCaseNames: [String] = [
    "Any",
    "as",
    "associatedtype",
    "break",
    "case",
    "catch",
    "class",
    "continue",
    "default",
    "defer",
    "deinit",
    "do",
    "else",
    "enum",
    "extension",
    "fallthrough",
    "false",
    "fileprivate",
    "for",
    "func",
    "guard",
    "if",
    "import",
    "in",
    "init",
    "inout",
    "internal",
    "is",
    "let",
    "nil",
    "operator",
    "precedencegroup",
    "private",
    "Protocol",
    "protocol",
    "public",
    "repeat",
    "rethrows",
    "return",
    "self",
    "Self",
    "static",
    "struct",
    "subscript",
    "super",
    "switch",
    "throw",
    "throws",
    "true",
    "try",
    "Type",
    "typealias",
    "var",
    "where",
    "while",
]
