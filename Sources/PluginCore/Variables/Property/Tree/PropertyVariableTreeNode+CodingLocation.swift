import SwiftSyntax
import SwiftSyntaxMacros

extension PropertyVariableTreeNode {
    /// Represents the location for decoding/encoding that the node needs
    /// to perform.
    ///
    /// Represents whether node needs to decode/encode directly
    /// from/to the decoder/encoder respectively or at path of a container
    struct CodingLocation: Variable {
        /// The context representing the nesting level.
        let context: Context
        /// Whether generated decoding rejects unsupported keys.
        let rejectUnknownKeys: Bool
        /// Whether strict validation is emitted after superclass decoding.
        let deferUnknownKeyValidation: Bool
        /// Additional keys accepted by the current decoding container.
        let additionalAllowedKeys: [String]
        /// Additional keys accepted at nested decoding container paths.
        let additionalAllowedKeysByPath: [String: [String]]
        /// The coding path represented by the current decoding location.
        let codingPath: [String]
        /// Paths whose generated validation is deferred.
        let skipUnknownKeyValidationPaths: Set<String>
        /// Whether direct decoding must preserve strict decoder metadata.
        let preserveDecoderMetadata: Bool
        /// Whether validation for the current root container is deferred.
        let skipCurrentContainerValidation: Bool
        /// The decoding/encoding progress.
        ///
        /// All the decoded/encoded variables and
        /// skipped variables are tracked in this instance.
        let progress: Progress

        /// Creates new instance with provided data.
        ///
        /// - Parameters:
        ///   - context: The context representing the nesting level.
        ///   - progress: The decoding/encoding progress.
        ///   - rejectUnknownKeys: Whether generated decoding rejects
        ///     unsupported keys.
        ///   - deferUnknownKeyValidation: Whether strict validation is
        ///     emitted after superclass decoding.
        private init(
            context: Context, progress: Progress, rejectUnknownKeys: Bool,
            deferUnknownKeyValidation: Bool, additionalAllowedKeys: [String],
            additionalAllowedKeysByPath: [String: [String]],
            codingPath: [String],
            skipUnknownKeyValidationPaths: Set<String>,
            preserveDecoderMetadata: Bool,
            skipCurrentContainerValidation: Bool
        ) {
            self.context = context
            self.progress = progress
            self.rejectUnknownKeys = rejectUnknownKeys
            self.deferUnknownKeyValidation = deferUnknownKeyValidation
            self.additionalAllowedKeys = additionalAllowedKeys
            self.additionalAllowedKeysByPath = additionalAllowedKeysByPath
            self.codingPath = codingPath
            self.skipUnknownKeyValidationPaths =
                skipUnknownKeyValidationPaths
            self.preserveDecoderMetadata = preserveDecoderMetadata
            self.skipCurrentContainerValidation =
                skipCurrentContainerValidation
        }

        /// Add provided variable to list of already decoded/encoded variable.
        ///
        /// - Parameter variable: The variable to add.
        func coded(_ variable: any PropertyVariable) {
            progress.coded.append(variable)
        }

        /// Added provided variable to list of pending variables.
        ///
        /// Stores pending variable with current context level
        /// in the progress instance.
        ///
        /// - Parameter variable: The variable to add.
        func pending(_ variable: any PropertyVariable) {
            progress.pending.append((context, variable))
        }

        /// Creates a new location with provided context.
        ///
        /// Creates new location with the provided context as top-level context.
        ///
        /// - Parameters:
        ///   - coder: The decoder/encoder for decoding/encoding.
        ///   - keyType: The `CodingKey` type.
        ///   - rejectUnknownKeys: Whether generated decoding rejects
        ///     unsupported keys.
        ///   - deferUnknownKeyValidation: Whether strict validation is
        ///     emitted after superclass decoding.
        ///
        /// - Returns: The new location updated with provided context.
        static func withCoder(
            _ coder: TokenSyntax, keyType: ExprSyntax,
            rejectUnknownKeys: Bool = false,
            deferUnknownKeyValidation: Bool = false,
            additionalAllowedKeys: [String] = [],
            additionalAllowedKeysByPath: [String: [String]] = [:],
            skipUnknownKeyValidationPaths: Set<String> = [],
            preserveDecoderMetadata: Bool = false,
            skipCurrentContainerValidation: Bool = false
        ) -> Self {
            .init(
                context: .coder(coder, keyType: keyType), progress: .init(),
                rejectUnknownKeys: rejectUnknownKeys,
                deferUnknownKeyValidation: deferUnknownKeyValidation,
                additionalAllowedKeys: additionalAllowedKeys,
                additionalAllowedKeysByPath: additionalAllowedKeysByPath,
                codingPath: [],
                skipUnknownKeyValidationPaths:
                    skipUnknownKeyValidationPaths,
                preserveDecoderMetadata: preserveDecoderMetadata,
                skipCurrentContainerValidation:
                    skipCurrentContainerValidation
            )
        }

        /// Creates a new location with provided context.
        ///
        /// - Parameters:
        ///   - container: The container for decoding/encoding.
        ///   - key: The `CodingKey` inside the container.
        ///
        /// - Returns: The new location updated with provided context.
        func withContainer(
            _ container: Context.Container, key: CodingKeysMap.Key
        ) -> Self {
            let codingPath = codingPath + [key.description]
            return .init(
                context: .container(container, key: key), progress: progress,
                rejectUnknownKeys: rejectUnknownKeys,
                deferUnknownKeyValidation: deferUnknownKeyValidation,
                additionalAllowedKeys:
                    additionalAllowedKeysByPath[
                        strictDecodingPathKey(codingPath)
                    ] ?? [],
                additionalAllowedKeysByPath: additionalAllowedKeysByPath,
                codingPath: codingPath,
                skipUnknownKeyValidationPaths:
                    skipUnknownKeyValidationPaths,
                preserveDecoderMetadata: preserveDecoderMetadata,
                skipCurrentContainerValidation: false
            )
        }

        /// The decoding/encoding location for an individual variable.
        var forVariable: PropertyCodingLocation {
            switch context {
            case .coder(let coder, keyType: _):
                if preserveDecoderMetadata {
                    return .coderWithMetadata(coder, method: nil)
                }
                return .coder(coder, method: nil)
            case .container(let container, let key):
                return .container(
                    container.name, key: key.expr, method: nil
                )
            }
        }

        /// Provides the syntax for decoding at the provided location.
        ///
        /// Provides syntax for remaining pending variables that
        /// weren't decoded due to dependencies.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The decoding location.
        ///
        /// - Returns: The generated decoding syntax.
        func decoding(
            in context: some MacroExpansionContext, from location: () = ()
        ) -> CodeBlockItemListSyntax {
            let pending = progress.pending.sorted { pending1, pending2 in
                pending2.variable.depends(on: pending1.variable)
            }
            return CodeBlockItemListSyntax {
                for (lContext, variable) in pending {
                    let location = lContext.forVariable
                    let syntax = variable.decoding(in: context, from: location)
                    switch lContext {
                    case .container(let container, key: _)
                    where container.isOptional:
                        switch variable.decodingFallback {
                        case .onlyIfMissing(let fallbacks):
                            try! IfExprSyntax(
                                """
                                if let \(container.name) = \(container.name)
                                """
                            ) {
                                syntax
                            } else: {
                                fallbacks
                            }
                        case .ifMissing(let fallbacks, ifError: let eFallbacks):
                            try! IfExprSyntax(
                                "if let \(container.name) = \(container.name)",
                                bodyBuilder: {
                                    syntax
                                },
                                elseIf: IfExprSyntax(
                                    "if \(container.name)Missing"
                                ) {
                                    fallbacks
                                } else: {
                                    eFallbacks
                                }
                            )
                        case .throw:
                            syntax
                        }
                    default:
                        syntax
                    }
                }
            }
        }

        /// Provides the syntax for encoding at the provided location.
        ///
        /// Doesn't provide any syntax for encoding.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The encoding location.
        ///
        /// - Returns: The generated encoding syntax.
        func encoding(
            in context: some MacroExpansionContext, to location: () = ()
        ) -> CodeBlockItemListSyntax {
            ""
        }

        /// The decoding/encoding progress.
        ///
        /// Stores the variables that are decoded already
        /// and pending to be decoded due to dependency.
        final class Progress {
            /// The pending variable and path pair type.
            typealias Pending = (Context, variable: any PropertyVariable)
            /// The variables that are already decoded.
            fileprivate(set) var coded: [any PropertyVariable] = []
            /// The variables and their path that are skipped
            /// decoding due to dependency.
            ///
            /// The decoding syntax for these variables can be created
            /// from the location instance.
            fileprivate(set) var pending: [Pending] = []
        }

        /// Represents the context for decoding/encoding that the node needs
        /// to perform.
        ///
        /// Represents whether node needs to decode/encode directly
        /// from/to the decoder/encoder respectively or at path of a container
        enum Context {
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
                case .container(let container, let key):
                    return .container(
                        container.name, key: key.expr, method: nil
                    )
                }
            }

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

                /// The syntax to use for this container.
                ///
                /// Adds `?` mark based on whether
                /// container variable is optional or not.
                var syntax: TokenSyntax {
                    let oToken: TokenSyntax = isOptional ? "?" : ""
                    return "\(name)\(oToken)"
                }
            }
        }
    }
}
