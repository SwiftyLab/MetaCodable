import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import OrderedCollections

extension CodableMacro.Registrar {
    /// A type storing variable and `CodingKey`
    /// data using the "trie" tree algorithm.
    ///
    /// Use `register` method to register new data and
    /// use `decoding`, `encoding` to get registered
    /// variable decoding/encoding expressions.
    ///
    /// See https://en.wikipedia.org/wiki/Trie
    /// for more information.
    struct Node {
        /// All the field data registered at this node.
        private(set) var datas: [Data]
        /// Nested registration node associated with keys.
        private(set) var children: OrderedDictionary<Key, Self>

        /// List of all the `CodingKey` registered
        /// at current node and children nodes.
        var allCodableKeys: OrderedSet<Key> {
            return OrderedSet(children.keys)
                .union(children.flatMap { $1.allCodableKeys })
        }

        /// List of all the metadata registered
        /// at current node and children nodes.
        var allDatas: OrderedSet<Data> {
            return OrderedSet(datas)
                .union(children.flatMap { $1.allDatas })
        }

        /// Creates a new node with provided metadata list and and linked nodes.
        ///
        /// - Parameters:
        ///   - datas: The list of metadata.
        ///   - children: The list of linked nodes associated with keys.
        ///
        /// - Returns: The newly created node instance.
        init(datas: [Data] = [], children: OrderedDictionary<Key, Self> = [:]) {
            self.datas = datas
            self.children = children
        }

        /// Register metadata for the provided `CodingKey` path.
        ///
        /// Create node at the `CodingKey` path if doesn't exist
        /// and register the metadata at the node.
        ///
        /// - Parameters:
        ///   - data: The metadata associated with field,
        ///           i.e. field name, type and additional macro metadata.
        ///   - keyPath: The `CodingKey` path where the value
        ///              will be decode/encoded.
        mutating func register(data: Data, keyPath: [Key]) {
            guard !keyPath.isEmpty else { datas.append(data); return }

            let key = keyPath.first!
            if children[key] == nil {
                children[key] = .init(datas: [], children: [:])
            }

            children[key]!.register(
                data: data,
                keyPath: Array(keyPath.dropFirst())
            )
        }
    }
}

// MARK: Decoding
extension CodableMacro.Registrar.Node {
    /// Provides the expression list syntax for decoding individual
    /// fields using registered metadata at current and linked nodes.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The decoding container variable for the current node.
    ///   - key: The `CodingKey` current node is associated with.
    ///
    /// - Returns: The generated expression list.
    func decoding(
        in context: some MacroExpansionContext,
        container: TokenSyntax,
        key: CodableMacro.Registrar.Key
    ) -> ExprListSyntax {
        return ExprListSyntax {
            for data in datas {
                data.decoding(in: context, from: container, key: key.expr)
            }
            self.nestedDecoding(in: context, container: container, key: key)
        }
    }

    /// Provides the expression list syntax for decoding individual
    /// fields using registered metadata at linked nodes.
    ///
    /// Creates variable for nested decoding container from current decoding
    /// container and passes it to children nodes for generating decoding
    /// expressions.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The decoding container variable for the current node.
    ///   - key: The `CodingKey` current node is associated with.
    ///
    /// - Returns: The generated expression list.
    func nestedDecoding(
        in context: some MacroExpansionContext,
        container: TokenSyntax,
        key: CodableMacro.Registrar.Key
    ) -> ExprListSyntax {
        return ExprListSyntax {
            let nestedContainer: TokenSyntax = "\(key.raw)_\(container)"
            for (cKey, node) in children {
                """
                let \(nestedContainer) = try \(container).nestedContainer(
                    keyedBy: \(key.type),
                    forKey: \(key.expr)
                )
                """ as ExprSyntax
                node.decoding(
                    in: context,
                    container: nestedContainer,
                    key: cKey
                )
            }
        }
    }
}

// MARK: Encoding
extension CodableMacro.Registrar.Node {
    /// Provides the expression list syntax for encoding individual
    /// fields using registered metadata at current and linked nodes.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The encoding container variable for the current node.
    ///   - key: The `CodingKey` current node is associated with.
    ///
    /// - Returns: The generated expression list.
    func encoding(
        in context: some MacroExpansionContext,
        container: TokenSyntax,
        key: CodableMacro.Registrar.Key
    ) -> ExprListSyntax {
        return ExprListSyntax {
            for data in datas {
                data.encoding(in: context, to: container, key: key.expr)
            }
            self.nestedEncoding(in: context, container: container, key: key)
        }
    }

    /// Provides the expression list syntax for encoding individual
    /// fields using registered metadata at linked nodes.
    ///
    /// Creates variable for nested encoding container from current encoding
    /// container and passes it to children nodes for generating encoding
    /// expressions.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The decoding container variable for the current node.
    ///   - key: The `CodingKey` current node is associated with.
    ///
    /// - Returns: The generated expression list.
    func nestedEncoding(
        in context: some MacroExpansionContext,
        container: TokenSyntax,
        key: CodableMacro.Registrar.Key
    ) -> ExprListSyntax {
        return ExprListSyntax {
            let nestedContainer: TokenSyntax = "\(key.raw)_\(container)"
            for (cKey, node) in children {
                """
                var \(nestedContainer) = \(container).nestedContainer(
                    keyedBy: \(key.type),
                    forKey: \(key.expr)
                )
                """ as ExprSyntax
                node.encoding(
                    in: context,
                    container: nestedContainer,
                    key: cKey
                )
            }
        }
    }
}
