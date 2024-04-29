import OrderedCollections
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension PropertyVariableTreeNode {
    /// A type storing variable and `CodingKey`
    /// data using the "trie" tree algorithm.
    ///
    /// Use `register` method to register new data and
    /// use this data to choose which variables to decode in
    /// `PropertyVariableTreeNode`.
    ///
    /// See https://en.wikipedia.org/wiki/Trie
    /// for more information.
    struct CodingData {
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

        /// Checks whether node has variables registered at the key provided.
        ///
        /// Checks if there is node available at the specified key and it has
        /// some variables or nested variables registered.
        ///
        /// - Parameter key: The key to search for.
        /// - Returns: Whether this node has children variables at the key.
        func hasKey(_ key: CodingKeysMap.Key) -> Bool {
            guard let child = children[key] else { return false }
            return !child.variables.isEmpty || !child.children.isEmpty
        }
    }
}
