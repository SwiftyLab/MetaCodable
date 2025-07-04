import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension AttributeExpander {
    /// Generates extension declarations for `Decodable` macro.
    ///
    /// From the variables registered by `Decodable` macro,
    /// `Decodable` protocol conformance and `CodingKey` type
    /// declarations are generated in separate extensions.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - protocols: The list of `Decodable` protocols to add
    ///     conformances to. These will always be `Decodable`.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated extension declarations.
    func decodableExpansion(
        for type: some TypeSyntaxProtocol,
        to protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        let dProtocol = TypeCodingLocation.Method.decode().protocol
        let decodable = variable.protocol(named: dProtocol, in: protocols)

        var extensions = [
            decoding(type: type, conformingTo: decodable, in: context),
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
