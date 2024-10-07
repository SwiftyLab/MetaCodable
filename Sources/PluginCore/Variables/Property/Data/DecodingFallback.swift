import SwiftSyntax

/// Represents possible fallback options for decoding failure.
///
/// When decoding fails for variable, variable can have fallback
/// to throw the failure error or handle it completely or handle
/// it only when variable is missing or `null`.
package enum DecodingFallback {
    /// Represents no fallback option.
    ///
    /// Indicates decoding failure error
    /// is thrown without any handling.
    case `throw`
    /// Represents fallback option for missing
    /// or `null` value.
    ///
    /// Indicates if variable data is missing or `null`,
    /// provided fallback syntax will be used for initialization.
    case onlyIfMissing(CodeBlockItemListSyntax)
    /// Represents fallback option handling
    /// decoding failure completely.
    ///
    /// Indicates for any type of failure error in decoding,
    /// provided fallback syntaxes will be used for initialization.
    ///
    /// First syntax will be used for errors due to missing or `null`
    /// value while second syntax will be used for all the other errors.
    case ifMissing(CodeBlockItemListSyntax, ifError: CodeBlockItemListSyntax)

    /// Represents container for decoding/encoding properties.
    typealias Container = PropertyVariableTreeNode.CodingLocation.Context
        .Container
    /// Represents generated syntax for decoding/encoding properties.
    typealias Generated = PropertyVariableTreeNode.Generated

    /// Provides the code block list syntax for decoding provided
    /// decoding location applying current fallback options.
    ///
    /// - Parameters:
    ///   - context: The decoding context to decode from.
    ///   - nestedContainer: The nested container name to use if present.
    ///   - nestedContainerHasVariables: Whether nested container has
    ///     some variables as direct children.
    ///   - decoding: The nested container decoding
    ///     code block generator.
    ///
    /// - Returns: The generated code block.
    func represented(
        context: PropertyVariableTreeNode.CodingLocation.Context,
        nestedContainer: TokenSyntax?,
        nestedContainerHasVariables: Bool,
        nestedDecoding decoding: (Container) -> Generated
    ) -> Generated {
        return switch context {
        case .coder(let coder, let kType):
            represented(
                decoder: coder, keyType: kType,
                nestedContainer: nestedContainer,
                nestedContainerHasVariables: nestedContainerHasVariables,
                nestedDecoding: decoding
            )
        case .container(let container, let key):
            represented(
                decodingContainer: container, fromKey: key,
                nestedContainer: nestedContainer,
                nestedContainerHasVariables: nestedContainerHasVariables,
                nestedDecoding: decoding
            )
        }
    }

    /// Provides the code block list syntax for decoding provided
    /// decoder applying current fallback options.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to decode from.
    ///   - type: The decoder container `CodingKey` type.
    ///   - nestedContainer: The nested container name to use if present.
    ///   - nestedContainerHasVariables: Whether nested container has
    ///     some variables as direct children.
    ///   - decoding: The nested container decoding
    ///     code block generator.
    ///
    /// - Returns: The generated code block.
    private func represented(
        decoder: TokenSyntax,
        keyType type: ExprSyntax,
        nestedContainer: TokenSyntax?,
        nestedContainerHasVariables: Bool,
        nestedDecoding decoding: (Container) -> Generated
    ) -> Generated {
        let isOptional: Bool
        let fallbacks: CodeBlockItemListSyntax
        switch self {
        case .ifMissing(_, ifError: let eFallbacks):
            isOptional = true
            fallbacks = eFallbacks
        default:
            isOptional = false
            fallbacks = []
        }

        let cToken = nestedContainer ?? "container"
        let container = Container(name: cToken, isOptional: isOptional)
        let generated = decoding(container)
        let containerSyntax = CodeBlockItemListSyntax {
            if nestedContainer == nil {
                let `try`: TokenSyntax = isOptional ? "try?" : "try"
                """
                let \(container.name) = \(`try`) \(decoder).container(keyedBy: \(type))
                """
            }
            generated.containerSyntax
        }

        let ifSyntax = generated.conditionalSyntax
        let cBinding =
            if nestedContainerHasVariables && !ifSyntax.isEmpty {
                container.name
            } else {
                "_" as TokenSyntax
            }

        let conditionalSyntax = CodeBlockItemListSyntax {
            if isOptional {
                try! IfExprSyntax(
                    """
                    if let \(cBinding) = \(container.name)
                    """
                ) {
                    ifSyntax
                } else: {
                    fallbacks
                }
            } else {
                ifSyntax
            }
        }
        return .init(
            containerSyntax: containerSyntax,
            codingSyntax: generated.codingSyntax,
            conditionalSyntax: conditionalSyntax
        )
    }

    /// Provides the code block list syntax for decoding provided
    /// container applying current fallback options.
    ///
    /// - Parameters:
    ///   - container: The container to decode from.
    ///   - key: The key from where to decode.
    ///   - nestedContainer: The nested container name to use if present.
    ///   - nestedContainerHasVariables: Whether nested container has
    ///     some variables as direct children.
    ///   - decoding: The nested container decoding
    ///     code block generator.
    ///
    /// - Returns: The generated code block.
    private func represented(
        decodingContainer container: Container,
        fromKey key: CodingKeysMap.Key,
        nestedContainer: TokenSyntax?,
        nestedContainerHasVariables: Bool,
        nestedDecoding decoding: (Container) -> Generated
    ) -> Generated {
        let nContainer = nestedContainer ?? "\(key.raw)_\(container.name)"
        let containerSyntax: CodeBlockItemListSyntax
        let codingSyntax: CodeBlockItemListSyntax
        let conditionalSyntax: CodeBlockItemListSyntax
        switch self {
        case .throw:
            let generated = decoding(
                .init(name: nContainer, isOptional: container.isOptional)
            )
            codingSyntax = generated.codingSyntax
            containerSyntax = CodeBlockItemListSyntax {
                if nestedContainer == nil {
                    """
                    let \(nContainer) = try \(container.syntax).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                    """
                }
                generated.containerSyntax
            }
            conditionalSyntax = generated.conditionalSyntax
        case .onlyIfMissing(let fallbacks):
            let generated = decoding(.init(name: nContainer, isOptional: true))
            let ifSyntax = generated.conditionalSyntax
            let nContainerBinding =
                if nestedContainerHasVariables && !ifSyntax.isEmpty {
                    nContainer
                } else {
                    "_" as TokenSyntax
                }

            codingSyntax = generated.codingSyntax
            containerSyntax = CodeBlockItemListSyntax {
                if nestedContainer == nil {
                    """
                    let \(nContainer) = ((try? \(container.syntax).decodeNil(forKey: \(key.expr))) == false) ? try \(container.syntax).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr)) : nil
                    """
                }
                generated.containerSyntax
            }
            conditionalSyntax = CodeBlockItemListSyntax {
                try! IfExprSyntax(
                    """
                    if let \(nContainerBinding) = \(nContainer)
                    """
                ) {
                    ifSyntax
                } else: {
                    fallbacks
                }
            }
        case let .ifMissing(fallbacks, ifError: eFallbacks):
            let generated = decoding(.init(name: nContainer, isOptional: true))
            let ifSyntax = generated.conditionalSyntax
            let nContainerBinding =
                if nestedContainerHasVariables && !ifSyntax.isEmpty {
                    nContainer
                } else {
                    "_" as TokenSyntax
                }

            let containerMissing: TokenSyntax = "\(nContainer)Missing"
            codingSyntax = generated.codingSyntax
            containerSyntax = CodeBlockItemListSyntax {
                if nestedContainer == nil {
                    "let \(nContainer): KeyedDecodingContainer<\(key.typeName)>?"
                    "let \(containerMissing): Bool"
                    try! IfExprSyntax(
                        """
                        if (try? \(container.syntax).decodeNil(forKey: \(key.expr))) == false
                        """
                    ) {
                        """
                        \(nContainer) = try? \(container.syntax).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                        """
                        "\(containerMissing) = false"
                    } else: {
                        "\(nContainer) = nil"
                        "\(containerMissing) = true"
                    }
                }
                generated.containerSyntax
            }
            conditionalSyntax = CodeBlockItemListSyntax {
                try! IfExprSyntax(
                    "if let \(nContainerBinding) = \(nContainer)",
                    bodyBuilder: {
                        ifSyntax
                    },
                    elseIf: IfExprSyntax("if \(containerMissing)") {
                        fallbacks
                    } else: {
                        eFallbacks
                    }
                )
            }
        }
        return .init(
            containerSyntax: containerSyntax, codingSyntax: codingSyntax,
            conditionalSyntax: conditionalSyntax
        )
    }
}

extension DecodingFallback {
    /// Checks whether the provided syntax causes early exit.
    ///
    /// Checks whether syntax as throwing statement at the end.
    ///
    /// - Parameter syntaxes: The syntaxes to check.
    /// - Returns: Whether the syntax throws at the end.
    private static func hasEarlyExit(
        in syntaxes: CodeBlockItemListSyntax
    ) -> Bool {
        return switch syntaxes.last?.item {
        case .stmt(let stmt) where stmt.is(ThrowStmtSyntax.self):
            true
        default:
            false
        }
    }

    /// Adds two decoding fallbacks into a single fallback.
    ///
    /// The generated single fallback represents both
    /// the fallback syntaxes added.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    ///
    /// - Returns: The generated fallback value.
    static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.throw, _), (_, .throw):
            return .throw
        case (.onlyIfMissing(let lf), .onlyIfMissing(let rf)),
            (.onlyIfMissing(let lf), .ifMissing(let rf, ifError: _)),
            (.ifMissing(let lf, ifError: _), .onlyIfMissing(let rf)):
            var fallbacks = lf
            if !hasEarlyExit(in: fallbacks) {
                fallbacks.append(contentsOf: rf)
            }
            return .onlyIfMissing(fallbacks)
        case let (.ifMissing(lf, ifError: lef), .ifMissing(rf, ifError: ref)):
            var fallbacks = lf
            if !hasEarlyExit(in: fallbacks) {
                fallbacks.append(contentsOf: rf)
            }
            var eFallbacks = lef
            if !hasEarlyExit(in: eFallbacks) {
                eFallbacks.append(contentsOf: ref)
            }
            return .ifMissing(fallbacks, ifError: eFallbacks)
        }
    }
}
