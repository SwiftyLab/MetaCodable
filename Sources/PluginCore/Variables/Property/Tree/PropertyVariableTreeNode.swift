import OrderedCollections
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A type storing variable and `CodingKey`
/// data using the "trie" tree algorithm.
///
/// Use `register` method to register new data and
/// use `decoding`, `encoding` to get registered
/// variable decoding/encoding expressions.
///
/// See https://en.wikipedia.org/wiki/Trie
/// for more information.
final class PropertyVariableTreeNode: Variable, VariableTreeNode {
    /// All the variables registered at this node.
    var variables: [any PropertyVariable] = []
    /// Nested registration node associated with keys.
    var children:
        OrderedDictionary<CodingKeysMap.Key, PropertyVariableTreeNode> = [:]
    /// Keys recognized by decoding at this container level.
    var allowedKeys: OrderedSet<String> = []

    /// The container for decoding variables linked to this node.
    ///
    /// This is used for caching the container variable name to be reused,
    /// allowing not to retrieve container repeatedly.
    private var decodingContainer: TokenSyntax?
    /// Whether the encoding container variable linked to this node
    /// should be declared as immutable.
    ///
    /// This is used to suppress mutability warning in case of
    /// internally tagged enums.
    var immutableEncodeContainer: Bool = false
}

// MARK: Decoding
extension PropertyVariableTreeNode {
    /// Provides the code block list syntax for decoding individual
    /// fields using registered variables at current and linked nodes.
    ///
    /// - Parameters:
    ///   - data: The data to use to choose variables to be decoded.
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the current node.
    ///
    /// - Returns: The generated code block list.
    func decoding(
        with data: CodingData?,
        in context: some MacroExpansionContext,
        from location: CodingLocation
    ) -> Generated {
        let directVariables = data?.variables ?? variables
        let hasDirectDecodableVariables = directVariables.contains {
            $0.decode ?? true
        }
        let childrenDecodable =
            data?.children.contains { _, node in
                node.linkedVariables.contains { $0.decode ?? true }
            }
            ?? children.contains { _, node in
                node.linkedVariables.contains { $0.decode ?? true }
            }
        let currentPath = strictDecodingPathKey(location.codingPath)
        let skipsValidation =
            location.skipCurrentContainerValidation
            || location.skipUnknownKeyValidationPaths.contains(currentPath)
        let hasMixedStrictValidation =
            location.rejectUnknownKeys
            && !location.deferUnknownKeyValidation
            && !skipsValidation
            && hasDirectDecodableVariables
            && childrenDecodable
        let directLocation: CodingLocation =
            if hasMixedStrictValidation {
                location.withCoder(
                    context.makeUniqueName("strictDecoder"),
                    preserveDecoderMetadata: true
                )
            } else {
                location
            }
        let strictDecoder: TokenSyntax? =
            if hasMixedStrictValidation,
                case .coder(let directDecoder, _) = directLocation.context
            {
                directDecoder
            } else {
                nil
            }
        let strictValidation =
            location.rejectUnknownKeys
            && !location.deferUnknownKeyValidation
            && !skipsValidation
            && !hasDirectDecodableVariables
        let currentAllowedKeys =
            Array(data?.allowedKeys ?? self.allowedKeys)
            + location.additionalAllowedKeys
        let allowedKeys: [String]? =
            strictValidation ? currentAllowedKeys : nil
        let deferredAllowedKeys: [String]? =
            hasMixedStrictValidation ? currentAllowedKeys : nil
        let wrapperSyntax: CodeBlockItemListSyntax = {
            guard
                let strictDecoder,
                case .coder(let decoder, _) = location.context
            else { return [] }
            let metadata = strictDecodingMetadataSyntax(
                ["": deferredAllowedKeys ?? []]
            )
            return
                "let \(strictDecoder) = MetaCodableStrictDecoder(decoder: \(decoder), allowedKeysByPath: \(metadata))"
        }()
        if let strictDecoder, let deferredAllowedKeys {
            let metadata = strictDecodingMetadataSyntax(
                ["": deferredAllowedKeys]
            )
            directLocation.deferValidation(
                "try \(strictDecoder).rejectUnknownKeys(allowedKeysByPath: \(metadata), type: Self.self)"
            )
        }
        let decodingSyntax = CodeBlockItemListSyntax {
            wrapperSyntax
            for variable in directVariables
            where variable.decode ?? true {
                if variable.dependenciesCount == 0 {
                    variable.decoding(
                        in: context, from: directLocation.forVariable
                    )
                    let _ = location.coded(variable)
                } else {
                    let _ = directLocation.pending(variable)
                }
            }
        }
        guard !(data?.children.isEmpty ?? children.isEmpty), childrenDecodable
        else {
            if strictValidation, !hasDirectDecodableVariables,
                case .coder(let decoder, _) = location.context
            {
                return .init(
                    containerSyntax: CodeBlockItemListSyntax {
                        strictDecodingValidationSyntax(
                            decoder: "\(decoder)" as ExprSyntax,
                            allowedKeys: allowedKeys
                        )
                    },
                    codingSyntax: decodingSyntax,
                    conditionalSyntax: ""
                )
            }
            return .init(
                containerSyntax: "", codingSyntax: decodingSyntax,
                conditionalSyntax: ""
            )
        }

        let decodableChildren = children.lazy
            .filter { data?.hasKey($0.key) ?? true }
        return decodableChildren.lazy
            .flatMap(\.value.linkedVariables)
            .map { variable in
                switch variable.decodingFallback {
                case .ifMissing where variable.dependenciesCount > 0:
                    return .ifMissing("", ifError: "")
                case .onlyIfMissing where variable.dependenciesCount > 0:
                    return .onlyIfMissing("")
                default:
                    return variable.decodingFallback
                }
            }

            .reduce(.ifMissing([], ifError: []), +)
            .represented(
                context: location.context,
                nestedContainer:
                    location.rejectUnknownKeys
                    && !location.deferUnknownKeyValidation
                    ? nil : decodingContainer,
                nestedContainerHasVariables:
                    location.skipCurrentContainerValidation
                    || !self.children.lazy
                        .flatMap(\.value.variables)
                        .filter { $0.decode ?? true }.isEmpty,
                allowedKeys: allowedKeys
            ) { container in
                self.decodingContainer = container.name
                let generated = decodableChildren.map { cKey, node in
                    node.decoding(
                        with: data?.children[cKey],
                        in: context,
                        from: location.withContainer(container, key: cKey)
                    )
                }.reduce(
                    .init(
                        containerSyntax: "", codingSyntax: "",
                        conditionalSyntax: ""
                    ), +
                )
                return .init(
                    containerSyntax: CodeBlockItemListSyntax {
                        generated.containerSyntax
                    },
                    codingSyntax: decodingSyntax,
                    conditionalSyntax: CodeBlockItemListSyntax {
                        generated.codingSyntax
                        generated.conditionalSyntax
                    }
                )
            }
    }

    /// Provides the code block list syntax for decoding individual
    /// fields using registered variables at current and linked nodes.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the current node.
    ///
    /// - Returns: The generated code block list.
    func decoding(
        in context: some MacroExpansionContext,
        from location: CodingLocation
    ) -> Generated {
        self.decoding(with: nil, in: context, from: location)
    }
}

// MARK: Encoding
extension PropertyVariableTreeNode {
    /// Provides the code block list syntax for encoding individual
    /// fields using registered metadata at current and linked nodes.
    ///
    /// - Parameters:
    ///   - data: The data to use to choose variables to be encoded.
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the current node.
    ///
    /// - Returns: The generated code block list.
    func encoding(
        with data: CodingData?,
        in context: some MacroExpansionContext,
        to location: CodingLocation
    ) -> Generated {
        let varLocation = location.context.forVariable
        let specifier: TokenSyntax = immutableEncodeContainer ? "let" : "var"
        let syntax = CodeBlockItemListSyntax {
            for variable in data?.variables ?? variables
            where variable.encode ?? true {
                variable.encoding(in: context, to: varLocation)
                let _ = location.coded(variable)
            }

            let childrenEncodable =
                data?.children.contains { _, node in
                    node.linkedVariables.contains { $0.encode ?? true }
                }
                ?? children.contains { _, node in
                    node.linkedVariables.contains { $0.encode ?? true }
                }
            if !(data?.children.isEmpty ?? children.isEmpty), childrenEncodable
            {
                switch location.context {
                case .coder(let encoder, let type):
                    let container: TokenSyntax = "container"
                    """
                    \(specifier) \(container) = \(encoder).container(keyedBy: \(type))
                    """
                    for (cKey, node) in children
                    where data?.hasKey(cKey) ?? true {
                        node.encoding(
                            with: data?.children[cKey],
                            in: context,
                            to: location.withContainer(
                                .init(name: container, isOptional: false),
                                key: cKey
                            )
                        ).combined()
                    }
                case .container(let container, let key):
                    let nestedContainer: TokenSyntax =
                        "\(key.raw)_\(container.name)"
                    """
                    \(specifier) \(nestedContainer) = \(container.name).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                    """
                    for (cKey, node) in children
                    where data?.hasKey(cKey) ?? true {
                        node.encoding(
                            with: data?.children[cKey],
                            in: context,
                            to: location.withContainer(
                                .init(name: nestedContainer, isOptional: false),
                                key: cKey
                            )
                        ).combined()
                    }
                }
            }
        }
        return .init(
            containerSyntax: "", codingSyntax: syntax, conditionalSyntax: ""
        )
    }

    /// Provides the code block list syntax for encoding individual
    /// fields using registered metadata at current and linked nodes.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the current node.
    ///
    /// - Returns: The generated code block list.
    func encoding(
        in context: some MacroExpansionContext,
        to location: CodingLocation
    ) -> Generated {
        self.encoding(with: nil, in: context, to: location)
    }
}
