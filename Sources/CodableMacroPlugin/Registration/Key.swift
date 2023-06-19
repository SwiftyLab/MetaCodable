import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

extension CodableMacro.Registrar {
    /// A type containing key data.
    ///
    /// This type also provides key associated
    /// `CodingKey` expression from `CaseMap`.
    struct Key: Equatable, Hashable, CustomStringConvertible {
        /// The key value.
        private let value: String
        /// The case map that generates `CodingKey`
        /// expressions for keys.
        private let map: CaseMap

        /// The `CodingKey` expression associated
        /// with the stored key `value`.
        var expr: ExprSyntax { "\(map.typeName).\(map.case(forKey: value)!)" }
        /// The `CodingKey` type expression that
        /// can be passed to functions as parameter.
        var type: ExprSyntax { map.type }
        /// The case name token syntax associated with the stored key `value`
        /// without wrapped in \`s.
        var raw: TokenSyntax { map.case(forKey: value)!.raw }
        /// A textual representation of this instance.
        ///
        /// Provides the underlying key value.
        var description: String { value }

        /// Creates a new key instance with provided
        /// key value and case map.
        ///
        /// - Parameters:
        ///   - value: A key value.
        ///   - map: The `CaseMap` that generates
        ///          `CodingKey` maps.
        ///
        /// - Returns: The newly created key instance.
        init(value: String, map: CaseMap) {
            self.value = value
            self.map = map
        }

        /// Hashes the key value of this key instance
        /// by feeding them into the given hasher.
        ///
        /// - Parameter hasher: The hasher to use when combining
        ///                     the components of this instance.
        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }

        /// Returns a Boolean value indicating whether two key instances
        /// are equal.
        ///
        /// - Parameters:
        ///   - lhs: A key value to compare.
        ///   - rhs: Another key value to compare.
        ///
        /// - Returns: True if both key instances have the same
        ///            key value, otherwise false.
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.value == rhs.value
        }
    }
}
