import OrderedCollections
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A variable value containing additional `CodingKey`s for decoding.
///
/// The `AliasedPropertyVariable` customizes decoding and initialization
/// by using the additional `CodingKey`s provided during initialization, by
/// checking if only one of the key has data associated.
struct AliasedPropertyVariable<Wrapped>: PropertyVariable, ComposedVariable
where Wrapped: PropertyVariable {
    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: Wrapped
    /// Additional possible keys for this variable.
    ///
    /// Represents all the additional `CodingKey`s that
    /// this variable could be encoded at.
    let additionalKeys: OrderedSet<CodingKeysMap.Key>

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Checks if variable data is present at the primary key or any of the
    /// additional keys and decodes data. If none of the keys found or multiple
    /// data found at the keys error is thrown.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        guard
            !additionalKeys.isEmpty,
            case let .container(container, key, method) = location
        else { return base.decoding(in: context, from: location) }
        var allKeys = [key]
        let additionalKeys = additionalKeys.filter { aKey in
            return aKey.expr.trimmedDescription != key.trimmedDescription
        }
        allKeys.append(contentsOf: additionalKeys.map(\.expr))
        let keysName: ExprSyntax = "\(CodingKeysMap.Key.name(for: name))Keys"
        let keyList = ArrayExprSyntax(expressions: allKeys)
        return CodeBlockItemListSyntax {
            """
            let \(keysName) = \(keyList).filter { \(container).allKeys.contains($0) }
            """
            """
            guard \(keysName).count == 1 else {
                let context = DecodingError.Context(
                    codingPath: \(container).codingPath,
                    debugDescription: "Invalid number of keys found, expected one."
                )
                throw DecodingError.typeMismatch(Self.self, context)
            }
            """
            base.decoding(
                in: context,
                from: .container(
                    container, key: "\(keysName)[0]", method: method)
            )
        }
    }
}

extension AliasedPropertyVariable: InitializableVariable
where Wrapped: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Wrapped.Initialization
}
