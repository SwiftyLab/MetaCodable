import SwiftSyntax

extension PropertyVariableTreeNode {
    /// Represents the syntax generated by `PropertyVariableTreeNode`.
    ///
    /// Represents the container retrieval syntax and conditional
    /// decoding/encoding code syntax generated.
    struct Generated {
        /// The container retrieval syntax.
        ///
        /// Represents container retrieval syntax that can be shared.
        let syntax: CodeBlockItemListSyntax
        /// The conditional syntax.
        ///
        /// Represents actual decoding/encoding syntax.
        let conditionalSyntax: CodeBlockItemListSyntax

        /// Combines both syntaxes into a single syntax.
        ///
        /// Combines container retrieval syntax and conditional syntax
        /// into single code syntax.
        ///
        /// - Returns: The combined code syntax.
        func combined() -> CodeBlockItemListSyntax {
            return CodeBlockItemListSyntax {
                syntax
                conditionalSyntax
            }
        }
    }
}

extension Sequence where Element == PropertyVariableTreeNode.Generated {
    /// Combines all the generated syntax into single syntax.
    ///
    /// Combines all the container retrieval syntaxes and conditional syntaxes
    /// into one container retrieval syntax and conditional syntax respectively.
    ///
    /// - Returns: The combined generated syntax.
    func aggregated() -> Element {
        let initial = Element(syntax: "", conditionalSyntax: "")
        return self.reduce(into: initial) { partialResult, generated in
            partialResult = .init(
                syntax: CodeBlockItemListSyntax {
                    partialResult.syntax
                    generated.syntax
                },
                conditionalSyntax: CodeBlockItemListSyntax {
                    partialResult.conditionalSyntax
                    generated.conditionalSyntax
                }
            )
        }
    }
}