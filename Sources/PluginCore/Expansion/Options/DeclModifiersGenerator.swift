import SwiftSyntax

extension AttributeExpander.Options {
    /// A declaration modifiers generator for `Codable`
    /// conformance implementations.
    ///
    /// This generator keeps track of original declaration
    /// and modifiers, then generates modifiers for
    /// `Decodable` or `Encodable` implementations.
    struct DeclModifiersGenerator {
        /// The declaration for which modifiers generated.
        let decl: DeclGroupSyntax

        /// The generated list of modifiers.
        ///
        /// If declaration has `public` or `package` modifier
        /// then same is generated, otherwise no extra modifiers
        /// generated.
        var generated: DeclModifierListSyntax {
            let `public` = DeclModifierSyntax(name: "public")
            let package = DeclModifierSyntax(name: "package")
            let modifiers = decl.modifiers
            var generatedModifiers = DeclModifierListSyntax()
            let accessModifier = [`public`, package].first { accessModifier in
                modifiers.contains { modifier in
                    modifier.name.text == accessModifier.name.text
                }
            }
            if let accessModifier {
                generatedModifiers.append(accessModifier)
            } else if modifiers.contains(where: { $0.name.text == "open" }) {
                generatedModifiers.append(`public`)
            }
            return generatedModifiers
        }
    }
}
