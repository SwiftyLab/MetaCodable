@_implementationOnly import OrderedCollections
@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxBuilder
@_implementationOnly import SwiftSyntaxMacros

/// A type storing variable and `CodingKey`
/// data using the "trie" tree algorithm.
///
/// Use `register` method to register new data and
/// use `decoding`, `encoding` to get registered
/// variable decoding/encoding expressions.
///
/// See https://en.wikipedia.org/wiki/Trie
/// for more information.
struct PropertyVariableTreeNode: Variable {
    /// Represents the location for decoding/encoding that the node needs
    /// to perform.
    ///
    /// Represents whether node needs to decode/encode directly
    /// from/to the decoder/encoder respectively or at path of a container
    enum CodingLocation {
        /// Represents a top-level decoding/encoding location.
        ///
        /// The node needs to perform decoding/encoding directly
        /// to the decoder/encoder provided, not nested at a `CodingKey`.
        ///
        /// - Parameters:
        ///   - coder: The decoder/encoder for decoding/encoding.
        ///   - keyType: The `CodingKey` type.
        case coder(_ coder: TokenSyntax, keyType: ExprSyntax)
        /// Represents decoding/encoding location at a `CodingKey`
        /// for a container.
        ///
        /// The node needs to perform decoding/encoding at the
        /// `CodingKey` inside the container provided.
        ///
        /// - Parameters:
        ///   - container: The container for decoding/encoding.
        ///   - key: The `CodingKey` inside the container.
        case container(_ container: TokenSyntax, key: CodingKeysMap.Key)

        /// The decoding/encoding location for individual variables.
        ///
        /// Maps current decoding/encoding location to individual
        /// variable decoding/encoding locations.
        var forVariable: PropertyCodingLocation {
            switch self {
            case .coder(let coder, keyType: _):
                return .coder(coder, method: nil)
            case .container(let container, key: let key):
                return .container(container, key: key.expr, method: nil)
            }
        }
    }
    /// All the variables registered at this node.
    private(set) var variables: [any PropertyVariable]
    /// Nested registration node associated with keys.
    private(set) var children: OrderedDictionary<CodingKeysMap.Key, Self>

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
        children: OrderedDictionary<CodingKeysMap.Key, Self> = [:]
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
    mutating func register(
        variable: any PropertyVariable,
        keyPath: [CodingKeysMap.Key]
    ) {
        guard !keyPath.isEmpty else { variables.append(variable); return }

        let key = keyPath.first!
        if children[key] == nil {
            children[key] = .init(variables: [], children: [:])
        }

        children[key]!.register(
            variable: variable,
            keyPath: Array(keyPath.dropFirst())
        )
    }
}

// MARK: Decoding
extension PropertyVariableTreeNode {
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
    ) -> CodeBlockItemListSyntax {
        return CodeBlockItemListSyntax {
            for variable in variables where variable.decode ?? true {
                variable.decoding(in: context, from: location.forVariable)
            }

            let childrenDecodable =
                children
                .contains { $1.linkedVariables.contains { $0.decode ?? true } }
            if !children.isEmpty, childrenDecodable {
                switch location {
                case .coder(let decoder, let type):
                    let container: TokenSyntax = "container"
                    """
                    let \(container) = try \(decoder).container(keyedBy: \(type))
                    """
                    for (cKey, node) in children {
                        node.decoding(
                            in: context,
                            from: .container(container, key: cKey)
                        )
                    }
                case .container(let container, let key):
                    DecodingFallback.aggregate(
                        fallbacks: children.lazy
                            .flatMap(\.value.linkedVariables)
                            .map(\.decodingFallback)
                    ).represented(
                        decodingContainer: container, fromKey: key
                    ) { nestedContainer in
                        return CodeBlockItemListSyntax {
                            for (cKey, node) in children {
                                node.decoding(
                                    in: context,
                                    from: .container(
                                        nestedContainer,
                                        key: cKey
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: Encoding
extension PropertyVariableTreeNode {
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
    ) -> CodeBlockItemListSyntax {
        return CodeBlockItemListSyntax {
            for variable in variables where variable.encode ?? true {
                variable.encoding(in: context, to: location.forVariable)
            }

            let childrenEncodable =
                children
                .contains { $1.linkedVariables.contains { $0.encode ?? true } }
            if !children.isEmpty, childrenEncodable {
                switch location {
                case .coder(let encoder, let type):
                    let container: TokenSyntax = "container"
                    """
                    var container = \(encoder).container(keyedBy: \(type))
                    """
                    for (cKey, node) in children {
                        node.encoding(
                            in: context,
                            to: .container(container, key: cKey)
                        )
                    }
                case .container(let container, let key):
                    let nestedContainer: TokenSyntax = "\(key.raw)_\(container)"
                    """
                    var \(nestedContainer) = \(container).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                    """
                    for (cKey, node) in children {
                        node.encoding(
                            in: context,
                            to: .container(nestedContainer, key: cKey)
                        )
                    }
                }
            }
        }
    }
}
