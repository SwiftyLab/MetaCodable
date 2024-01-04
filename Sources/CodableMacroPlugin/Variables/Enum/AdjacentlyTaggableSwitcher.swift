@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type of `EnumSwitcherVariable` that can have adjacent tagging.
///
/// Only internally tagged enums can have adjacent tagging, while externally
/// tagged enums can't have adjacent tagging.
protocol AdjacentlyTaggableSwitcher: EnumSwitcherVariable {
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
    func registering(
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
    func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        keyPath: [CodingKeysMap.Key]
    ) -> Self {
        var node = node
        node.register(variable: variable, keyPath: keyPath)
        return .init(
            encodeContainer: encodeContainer,
            identifier: identifier, identifierType: identifierType,
            node: node, keys: keys,
            decl: decl, variableBuilder: variableBuilder
        )
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
