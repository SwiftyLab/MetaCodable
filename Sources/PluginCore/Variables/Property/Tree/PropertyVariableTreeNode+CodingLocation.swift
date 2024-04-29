import SwiftSyntax

extension PropertyVariableTreeNode {
    /// Represents the location for decoding/encoding that the node needs
    /// to perform.
    ///
    /// Represents whether node needs to decode/encode directly
    /// from/to the decoder/encoder respectively or at path of a container
    enum CodingLocation {
        /// Represents the container for decoding/encoding.
        struct Container {
            /// The variable name of the container.
            ///
            /// This name is used for decoding/encoding syntax generation.
            let name: TokenSyntax
            /// Whether container is of optional type.
            ///
            /// Can be used to check whether container needs to be
            /// unwrapped first to proceed with decoding/encoding.
            let isOptional: Bool

            var syntax: TokenSyntax {
                let oToken: TokenSyntax = isOptional ? "?" : ""
                return "\(name)\(oToken)"
            }
        }

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
        case container(_ container: Container, key: CodingKeysMap.Key)

        /// The decoding/encoding location for individual variables.
        ///
        /// Maps current decoding/encoding location to individual
        /// variable decoding/encoding locations.
        var forVariable: PropertyCodingLocation {
            switch self {
            case .coder(let coder, keyType: _):
                return .coder(coder, method: nil)
            case .container(let container, key: let key):
                return .container(container.name, key: key.expr, method: nil)
            }
        }
    }
}
