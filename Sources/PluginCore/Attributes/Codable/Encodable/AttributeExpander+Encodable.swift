import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension AttributeExpander {
    /// Generates extension declarations for `Encodable` macro.
    ///
    /// From the variables registered by `Encodable` macro,
    /// `Encodable` protocol conformance and `CodingKey` type
    /// declarations are generated in separate extensions.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - protocols: The list of `Encodable` protocols to add
    ///     conformances to. These will always be `Encodable`.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated extension declarations.
    func encodableExpansion(
        for type: some TypeSyntaxProtocol,
        to protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        let eProtocol = TypeCodingLocation.Method.encode.protocol
        let encodable = variable.protocol(named: eProtocol, in: protocols)

        var extensions = [
            encoding(type: type, conformingTo: encodable, in: context),
            codingKeys(for: type, confirmingTo: protocols, in: context),
        ].compactMap { $0 }
        for index in extensions.indices {
            // attach available attributes from original declaration
            // to generated expanded declaration
            extensions[index].attributes = AttributeListSyntax {
                for attr in options.availableAttributes {
                    .attribute(attr)
                }
                extensions[index].attributes
            }
        }
        return extensions
    }
}
