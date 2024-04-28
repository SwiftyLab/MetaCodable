import OrderedCollections
import SwiftSyntax
import SwiftSyntaxMacros

/// A map containing all the case names
/// for keys in a particular type.
///
/// This map avoids conflicting case names
/// for similar sounding keys and duplicate
/// case definitions for keys declared
/// multiple times.
package final class CodingKeysMap {
    /// Generated enum type name.
    let typeName: TokenSyntax
    /// The fallback type name to use if no keys added.
    ///
    /// Uses this type in `type` expression instead of `typeName`
    /// if no `CodingKey` added/used.
    let fallbackTypeName: TokenSyntax?

    /// Generated enum type expression that can be passed
    /// to functions as parameter.
    ///
    /// Uses `fallbackTypeName`if provided and no key is used
    /// in generated syntax, otherwise `typeName` is used.
    var type: ExprSyntax {
        guard
            data.isEmpty, usedKeys.isEmpty, let fallbackTypeName
        else { return "\(typeName).self" }
        return "\(fallbackTypeName).self"
    }

    /// The key and associated
    /// case name syntax map.
    ///
    /// Kept up-to-date by
    /// `add(forKeys:field:context:)`
    /// method.
    private var data: OrderedDictionary<String, Case> = [:]
    /// The `CodingKey`s that have been used.
    ///
    /// Represents these `CodingKey`s have been used
    /// in generated code syntax and must be present as case
    /// in generated `CodingKey` enum declaration.
    private var usedKeys: Set<String> = []

    /// Creates a new case-map with provided enum name.
    ///
    /// The generated enum declaration has the name as provided.
    ///
    /// - Parameters:
    ///   - typeName: The enum type name generated.
    ///   - fallbackTypeName: The fallback type to be used in absense of keys.
    ///
    /// - Returns: Created case-map.
    package init(typeName: TokenSyntax, fallbackTypeName: TokenSyntax? = nil) {
        self.typeName = typeName
        self.fallbackTypeName = fallbackTypeName
        self.data = [:]
    }

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
    ///     * If current cases in the `CodingKeysMap` doesn't contain built
    ///       string, and built string doesn't conflict with existing Swift
    ///       keywords in `invalidCaseNames` then built string added as
    ///       case name for the key.
    ///     * If built string is already present as case name,
    ///       `MacroExpansionContext.makeUniqueName`
    ///       used to create unique case name with the built string
    ///       as input.
    ///     * If built string is already conflicts with
    ///       Swift keywords in `invalidCaseNames`,
    ///       then built string is wrapped with \` and checked
    ///       if present in current cases in the `CodingKeysMap`.
    ///       If not present new string added as case name,
    ///       otherwise previous rule is used.
    ///
    /// - Parameters:
    ///   - keys: The `CodingKey`s path for the field's value.
    ///   - field: The optional field located at the `CodingKey` path.
    ///   - context: The macro expansion context.
    func add(
        keys: [String] = [],
        field: TokenSyntax? = nil,
        context: some MacroExpansionContext
    ) -> [Key] {
        guard !keys.isEmpty else { return [] }
        var currentCases: [String] { data.values.map(\.name) }

        if let field {
            let fieldIncluded = currentCases.contains(Key.name(for: field).text)
            switch data[keys.last!] {
            case .none where !fieldIncluded, .builtWithKey where !fieldIncluded:
                guard keys.count > 1 else { fallthrough }
                data[keys.last!] = .nestedKeyField(field)
            case .nestedKeyField where !fieldIncluded:
                guard keys.count == 1 else { fallthrough }
                data[keys.last!] = .field(field)
            default:
                break
            }
        }

        for key in keys where data[key] == nil {
            var fieldName = camelCased(str: key)
            if doesBeginWithNumber(str: fieldName) {
                fieldName = "key\(fieldName)"
            }

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
        return keys.map { Key(value: $0, map: self) }
    }

    /// The case name token syntax available for a key.
    ///
    /// Adds key to the list of used keys, as this method is invoked to use
    /// key in generated code syntax.
    ///
    /// - Parameter key: The key to look up against.
    /// - Returns: The token syntax for case name stored against
    ///   a key if exists. Otherwise `nil` returned.
    ///
    /// - Note: Should only be used after case names generated
    ///   or all the keys for a particular type.
    func `case`(forKey key: String) -> TokenSyntax? {
        usedKeys.insert(key)
        return data[key]?.token
    }

    /// Creates an enum declaration from the current maps of cases
    /// and key values.
    ///
    /// The generated enum is a raw enum of `String` type
    /// and confirms to `CodingKey`.
    ///
    /// Only keys used in generated code syntax is present in this enum.
    ///
    /// - Parameter context: The macro expansion context.
    /// - Returns: The generated enum declaration syntax.
    func decl(in context: some MacroExpansionContext) -> DeclSyntax? {
        guard !data.isEmpty, !usedKeys.isEmpty else { return nil }
        let clause = InheritanceClauseSyntax {
            InheritedTypeSyntax(type: "String" as TypeSyntax)
            InheritedTypeSyntax(type: "CodingKey" as TypeSyntax)
        }
        let decl = EnumDeclSyntax(name: typeName, inheritanceClause: clause) {
            for (key, `case`) in data where usedKeys.contains(key) {
                "case \(`case`.token) = \(literal: key)" as DeclSyntax
            }
        }
        return DeclSyntax(decl)
    }
}

fileprivate extension CodingKeysMap {
    /// Creates camel case `String`
    ///
    /// Removes non-alphanumeric characters
    /// and makes the letters just after these
    /// characters uppercase.
    ///
    /// First letter is made lowercase.
    ///
    /// - Parameter str: The input `String`.
    /// - Returns: The created `String`.
    func camelCased(str: String) -> String {
        return CodingKeyTransformer(strategy: .camelCase).transform(key: str)
    }

    /// Check if `String` begins with number.
    ///
    /// Used to check whether key name begins with number.
    ///
    /// - Parameter str: The input `String`.
    /// - Returns: Whether `String` begins with number.
    func doesBeginWithNumber(str: String) -> Bool {
        if #available(macOS 13, iOS 16, macCatalyst 16, tvOS 16, watchOS 9, *) {
            return try! #/^[0-9]+[a-zA-Z0-9]*/#.wholeMatch(in: str) != nil
        } else {
            return str.range(
                of: "^[0-9]+[a-zA-Z0-9]*",
                options: .regularExpression
            ) != nil
        }
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
    "package",
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
