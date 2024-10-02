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
final class PropertyVariableTreeNode: Variable {
    /// All the variables registered at this node.
    private(set) var variables: [any PropertyVariable]
    /// Nested registration node associated with keys.
    private(set) var children:
        OrderedDictionary<CodingKeysMap.Key, PropertyVariableTreeNode>

    /// The container for decoding variables linked to this node.
    ///
    /// This is used for caching the container variable name to be reused,
    /// allowing not to retrieve container repeatedly.
    private var decodingContainer: TokenSyntax?
    /// Whether the encoding container variable  linked to this node
    /// should be declared as immutable.
    ///
    /// This is used to suppress mutability warning in case of
    /// internally tagged enums.
    private var immutableEncodeContainer: Bool = false

    /// List of all the linked variables registered.
    ///
    /// Gets all variables at current node
    /// and children nodes.
    var linkedVariables: [any PropertyVariable] {
        return variables + children.flatMap { $1.linkedVariables }
    }

    /// Creates a new node with provided variables and and linked nodes.
    ///
    /// - Parameters:
    ///   - variables: The list of variables.
    ///   - children: The list of linked nodes associated with keys.
    ///
    /// - Returns: The newly created node instance.
    init(
        variables: [any PropertyVariable] = [],
        children: OrderedDictionary<
            CodingKeysMap.Key, PropertyVariableTreeNode
        > = [:]
    ) {
        self.variables = variables
        self.children = children
    }

    /// Register variable for the provided `CodingKey` path.
    ///
    /// Create node at the `CodingKey` path if doesn't exist
    /// and register the variable at the node.
    ///
    /// - Parameters:
    ///   - variable: The variable data, i.e. name, type and
    ///     additional macro metadata.
    ///   - keyPath: The `CodingKey` path where the value
    ///     will be decode/encoded.
    ///   - immutableEncodeContainer: Whether the encoding container variable
    ///     direct parent of `variable` should be declared as immutable.
    func register(
        variable: any PropertyVariable,
        keyPath: [CodingKeysMap.Key],
        immutableEncodeContainer: Bool = false
    ) {
        guard !keyPath.isEmpty else { variables.append(variable); return }

        let key = keyPath.first!
        if children[key] == nil {
            children[key] = .init(variables: [], children: [:])
        }

        if keyPath.count == 1 {
            precondition(
                !immutableEncodeContainer
                    || linkedVariables.filter { $0.encode ?? true }.isEmpty
            )
            self.immutableEncodeContainer = immutableEncodeContainer
        }

        children[key]!.register(
            variable: variable,
            keyPath: Array(keyPath.dropFirst()),
            immutableEncodeContainer: immutableEncodeContainer
        )
    }
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
        let decodingSyntax = CodeBlockItemListSyntax {
            for variable in data?.variables ?? variables
            where variable.decode ?? true {
                variable.decoding(in: context, from: location.forVariable)
            }
        }
        let childrenDecodable =
            data?.children.contains { _, node in
                node.linkedVariables.contains { $0.decode ?? true }
            }
            ?? children.contains { _, node in
                node.linkedVariables.contains { $0.decode ?? true }
            }
        guard !(data?.children.isEmpty ?? children.isEmpty), childrenDecodable
        else {
            return .init(
                containerSyntax: "", codingSyntax: decodingSyntax,
                conditionalSyntax: ""
            )
        }

        let decodableChildren = children.lazy
            .filter { data?.hasKey($0.key) ?? true }
        return decodableChildren.lazy
            .flatMap(\.value.linkedVariables)
            .map(\.decodingFallback)
            .reduce(.ifMissing([], ifError: []), +)
            .represented(
                location: location, nestedContainer: self.decodingContainer,
                nestedContainerHasVariables: !self.children.lazy
                    .flatMap(\.value.variables)
                    .filter { $0.decode ?? true }.isEmpty
            ) { container in
                self.decodingContainer = container.name
                let generated = decodableChildren.map { cKey, node in
                    return node.decoding(
                        with: data?.children[cKey],
                        in: context,
                        from: .container(container, key: cKey)
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
        return self.decoding(with: nil, in: context, from: location)
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
        let specifier: TokenSyntax = immutableEncodeContainer ? "let" : "var"
        let syntax = CodeBlockItemListSyntax {
            for variable in data?.variables ?? variables
            where variable.encode ?? true {
                variable.encoding(in: context, to: location.forVariable)
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
                switch location {
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
                            to: .container(
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
                            to: .container(
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
        return self.encoding(with: nil, in: context, to: location)
    }
}
