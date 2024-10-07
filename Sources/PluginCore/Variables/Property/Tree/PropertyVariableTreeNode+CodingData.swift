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
    struct CodingData: VariableTreeNode {
        /// All the variables registered at this node.
        var variables: [any PropertyVariable] = []
        /// Nested registration node associated with keys.
        var children = OrderedDictionary<CodingKeysMap.Key, Self>()
        /// Whether the encoding container variable linked to this node
        /// should be declared as immutable.
        ///
        /// This is used to suppress mutability warning in case of
        /// internally tagged enums.
        var immutableEncodeContainer: Bool = false
    }
}

protocol VariableTreeNode {
    /// All the variables registered at this node.
    var variables: [any PropertyVariable] { get set }
    /// Nested registration node associated with keys.
    var children: OrderedDictionary<CodingKeysMap.Key, Self> { get set }
    /// Whether the encoding container variable linked to this node
    /// should be declared as immutable.
    ///
    /// This is used to suppress mutability warning in case of
    /// internally tagged enums.
    var immutableEncodeContainer: Bool { get set }
    /// Creates a new tree node instance.
    ///
    /// Creates new node with empty children and data.
    init()
}

extension VariableTreeNode {
    /// List of all the linked variables registered.
    ///
    /// Gets all variables at current node
    /// and children nodes.
    var linkedVariables: [any PropertyVariable] {
        return variables + children.flatMap { $1.linkedVariables }
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
    mutating func register<Variable: PropertyVariable>(
        variable: Variable, keyPath: [CodingKeysMap.Key],
        immutableEncodeContainer: Bool = false
    ) {
        if keyPath.isEmpty {
            let depIndex = variables.firstIndex { $0.depends(on: variable) }
            if let index = depIndex {
                variables.insert(variable, at: index)
            } else {
                variables.append(variable)
            }
            return
        }

        let key = keyPath.first!
        if children[key] == nil {
            children[key] = .init()
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
