@_implementationOnly import SwiftSyntax

extension CaseMap {
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
}
