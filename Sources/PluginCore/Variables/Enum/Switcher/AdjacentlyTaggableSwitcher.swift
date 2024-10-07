import SwiftSyntax
import SwiftSyntaxMacros

/// A type of `EnumSwitcherVariable` that can have adjacent tagging.
///
/// Only internally tagged enums can have adjacent tagging, while externally
/// tagged enums can't have adjacent tagging.
protocol AdjacentlyTaggableSwitcher: EnumSwitcherVariable {
    /// Provides the syntax for decoding at the provided location and decoder.
    ///
    /// The generated implementation decodes the identifier variable from
    /// provided location, the the content of variable decoded from `decoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///   - decoder: The decoder content will be decoded from.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation,
        contentAt decoder: TokenSyntax
    ) -> CodeBlockItemListSyntax
    /// Provides the syntax for encoding at the provided location and encoder.
    ///
    /// The generated implementation encodes the identifier variable to provided
    /// location, the the content of variable encoded to provided `encoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///   - encoder: The encoder content will be encoded to.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation,
        contentAt encoder: TokenSyntax
    ) -> CodeBlockItemListSyntax

    /// Register variable for the provided `CodingKey` path.
    ///
    /// Creates new switcher variable of this type updating with provided
    /// variable registration.
    ///
    /// - Parameters:
    ///   - variable: The variable data, i.e. name, type and
    ///     additional macro metadata.
    ///   - keyPath: The `CodingKey` path where the value
    ///     will be decode/encoded.
    ///
    /// - Returns: Newly created variable updating registration.
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        keyPath: [CodingKeysMap.Key]
    ) -> Self
}

extension InternallyTaggedEnumSwitcher: AdjacentlyTaggableSwitcher {
    /// Register variable for the provided `CodingKey` path.
    ///
    /// Creates new switcher variable of this type updating with provided
    /// variable registration.
    ///
    /// Registers variable at the provided `CodingKey` path on the current node.
    ///
    /// - Parameters:
    ///   - variable: The variable data, i.e. name, type and
    ///     additional macro metadata.
    ///   - keyPath: The `CodingKey` path where the value
    ///     will be decode/encoded.
    ///
    /// - Returns: Newly created variable updating registration.
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        keyPath: [CodingKeysMap.Key]
    ) -> Self {
        node.register(variable: variable, keyPath: keyPath)
        return self
    }

    /// Provides the syntax for decoding at the provided location and decoder.
    ///
    /// The generated implementation decodes the identifier variable from
    /// provided location, the the content of variable decoded from `decoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///   - decoder: The decoder content will be decoded from.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation,
        contentAt decoder: TokenSyntax
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return CodeBlockItemListSyntax {
            "let \(identifier): \(identifierType)"
            node.decoding(
                in: context, from: .withCoder(coder, keyType: location.keyType)
            ).combined()
            self.decodeSwitchExpression(
                over: "\(identifier)", at: location, from: decoder,
                in: context, withDefaultCase: true
            ) { _ in "" }
        }
    }

    /// Provides the syntax for encoding at the provided location and encoder.
    ///
    /// The generated implementation encodes the identifier variable to provided
    /// location, the the content of variable encoded to provided `encoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///   - encoder: The encoder content will be encoded to.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation,
        contentAt encoder: TokenSyntax
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return CodeBlockItemListSyntax {
            node.encoding(
                in: context, to: .withCoder(coder, keyType: location.keyType)
            ).combined()
            self.encodeSwitchExpression(
                over: location.selfValue, at: location, from: encoder,
                in: context, withDefaultCase: location.hasDefaultCase
            ) { name in
                let base = self.base(name)
                let key: [String] = []
                let input = Registration(decl: decl, key: key, variable: base)
                let output = variableBuilder(input)
                let keyExpr = keys.last!.expr
                return output.variable.encoding(
                    in: context,
                    to: .container(encodeContainer, key: keyExpr, method: nil)
                )
            }
        }
    }
}

extension Registration
where Var: AdjacentlyTaggableSwitcher, Decl: AttributableDeclSyntax {
    /// Checks if enum declares adjacent tagging.
    ///
    /// Checks if enum-case content path provided with `CodedAt` macro.
    ///
    /// - Parameters:
    ///   - contentDecoder: The mapped name for decoder.
    ///   - contentEncoder: The mapped name for encoder.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Variable registration with adjacent tagging data if exists.
    func checkForAdjacentTagging(
        contentDecoder: TokenSyntax, contentEncoder: TokenSyntax,
        codingKeys: CodingKeysMap, context: MacroExpansionContext
    ) -> Registration<Decl, Key, AnyEnumSwitcher> {
        guard
            let attr = ContentAt(from: decl),
            case let keyPath = attr.keyPath(withExisting: []),
            !keyPath.isEmpty
        else { return self.updating(with: variable.any) }
        let variable = AdjacentlyTaggedEnumSwitcher(
            base: variable,
            contentDecoder: contentDecoder, contentEncoder: contentEncoder,
            keyPath: keyPath, codingKeys: codingKeys, context: context
        )
        return self.updating(with: variable.any)
    }
}
