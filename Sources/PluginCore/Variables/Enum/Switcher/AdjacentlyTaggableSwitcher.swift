import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A type of `EnumSwitcherVariable` that can have adjacent tagging.
///
/// Only internally tagged enums can have adjacent tagging, while externally
/// tagged enums can't have adjacent tagging.
protocol AdjacentlyTaggableSwitcher: EnumSwitcherVariable {
    /// Provides the syntax for decoding at the provided location and decoder.
    ///
    /// The generated implementation decodes the identifier variable from
    /// provided location, the the content of variable decoded from `decoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///   - decoder: The decoder content will be decoded from.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation,
        contentAt decoder: TokenSyntax
    ) -> CodeBlockItemListSyntax

    /// Provides the syntax for encoding at the provided location and encoder.
    ///
    /// The generated implementation encodes the identifier variable to provided
    /// location, the the content of variable encoded to provided `encoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///   - encoder: The encoder content will be encoded to.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation,
        contentAt encoder: TokenSyntax
    ) -> CodeBlockItemListSyntax

    /// Register variable for decoding at the provided `CodingKey` path.
    ///
    /// Creates a new switcher variable of this type that incorporates the provided
    /// variable registration for the decoding process.
    ///
    /// - Parameters:
    ///   - variable: The variable data to register, containing metadata such as name,
    ///     type, and coding attributes. This is typically a `CoderVariable` that handles
    ///     the decoding process.
    ///   - decodingKeyPath: The `CodingKey` path where the value will be decoded from.
    ///     This path determines the location in the encoded input from which the variable's
    ///     value will be extracted.
    ///
    /// - Returns: The updated instance of `Self` with the variable registered.
    @discardableResult
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        decodingKeyPath: [CodingKeysMap.Key]
    ) -> Self

    /// Register variable for encoding at the provided `CodingKey` path.
    ///
    /// Creates a new switcher variable of this type that incorporates the provided
    /// variable registration for the encoding process.
    ///
    /// - Parameters:
    ///   - variable: The variable data to register, containing metadata such as name,
    ///     type, and coding attributes. This is typically a `CoderVariable` that handles
    ///     the encoding process.
    ///   - encodingKeyPath: The `CodingKey` path where the value will be encoded to.
    ///     This path determines the location in the encoded output where the variable's
    ///     value will be stored.
    ///
    /// - Returns: The updated instance of `Self` with the variable registered.
    @discardableResult
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        encodingKeyPath: [CodingKeysMap.Key]
    ) -> Self
}

extension InternallyTaggedEnumSwitcher: AdjacentlyTaggableSwitcher {
    /// Register variable for decoding at the provided `CodingKey` path.
    ///
    /// Creates a new switcher variable of this type that incorporates the provided
    /// variable registration. This method registers the variable at the specified
    /// `CodingKey` path on the current decoding node.
    ///
    /// - Parameters:
    ///   - variable: The variable data to register, containing metadata such as name,
    ///     type, and coding attributes. This is typically a `CoderVariable` that handles
    ///     the decoding process.
    ///   - decodingKeyPath: The `CodingKey` path where the value will be decoded from.
    ///     This path determines the location in the encoded input from which the variable's
    ///     value will be extracted.
    ///
    /// - Returns: The updated instance of `Self` with the variable registered.
    @discardableResult
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        decodingKeyPath: [CodingKeysMap.Key]
    ) -> Self {
        decodingNode.register(variable: variable, keyPath: decodingKeyPath)
        return self
    }

    /// Register variable for encoding at the provided `CodingKey` path.
    ///
    /// Creates a new switcher variable of this type that incorporates the provided
    /// variable registration. This method registers the variable at the specified
    /// `CodingKey` path on the current encoding node.
    ///
    /// - Parameters:
    ///   - variable: The variable data to register, containing metadata such as name,
    ///     type, and coding attributes. This is typically a `CoderVariable` that handles
    ///     the encoding process.
    ///   - encodingKeyPath: The `CodingKey` path where the value will be encoded to.
    ///     This path determines the location in the encoded output where the variable's
    ///     value will be stored.
    ///
    /// - Returns: The updated instance of `Self` with the variable registered.
    @discardableResult
    mutating func registering(
        variable: AdjacentlyTaggedEnumSwitcher<Self>.CoderVariable,
        encodingKeyPath: [CodingKeysMap.Key]
    ) -> Self {
        encodingNode.register(variable: variable, keyPath: encodingKeyPath)
        return self
    }

    /// Provides the syntax for decoding at the provided location and decoder.
    ///
    /// The generated implementation decodes the identifier variable from
    /// provided location, the the content of variable decoded from `decoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///   - decoder: The decoder content will be decoded from.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation,
        contentAt decoder: TokenSyntax
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        let container = self.variable.decodeContainer
        let containerType = self.identifierContainerType()
        let idetifierDecodingSyntax =
            EnumVariable.CaseValue.TypeOf.all(
                inheritedType: identifierType
            ).compactMap { type in
                let identifier: TokenSyntax =
                    "\(self.identifier)\(type.nameSuffix())"
                let switchExpr = self.decodeSwitchExpression(
                    over: .init(syntax: "\(identifier)", type: type),
                    at: location, from: decoder,
                    in: context, withDefaultCase: true,
                    forceDecodingReturn: forceDecodingReturn
                ) { _ in "" }

                guard let switchExpr = switchExpr, switchExpr.cases.count > 1
                else { return nil }
                return CodeBlockItemListSyntax {
                    let typesyntax = type.syntax(
                        optional: identifierType == nil)
                    let (variable, key) = identifierVariableAndKey(
                        identifier, withType: typesyntax, context: context
                    )
                    let decodingKey = codingKeys.add(
                        keys: key.decoding, field: identifier, context: context
                    ).last!.expr

                    "let \(identifier): \(type.syntax(optional: identifierType == nil))"
                    variable.decoding(
                        in: context,
                        from: .container(
                            container, key: decodingKey, method: nil)
                    )

                    switch variable.decodingFallback {
                    case .ifMissing where identifierType == nil,
                        .onlyIfMissing where identifierType == nil:
                        try! IfExprSyntax(
                            """
                            if let \(identifier) = \(identifier))
                            """
                        ) {
                            switchExpr
                        }
                    default:
                        switchExpr
                    }
                }
            } as [CodeBlockItemListSyntax]

        return CodeBlockItemListSyntax {
            if !idetifierDecodingSyntax.isEmpty {
                "var \(container): \(containerType)"
                decodingNode.decoding(
                    in: context,
                    from: .withCoder(coder, keyType: location.keyType)
                ).combined()

                if containerType.isOptionalTypeSyntax {
                    let topContainerOptional = decodingNode.children
                        .flatMap(\.value.linkedVariables)
                        .allSatisfy { variable in
                            switch variable.decodingFallback {
                            case .ifMissing:
                                return true
                            default:
                                return false
                            }
                        }

                    let header: SyntaxNodeString =
                        topContainerOptional
                        ? "if let \(container) = \(container), let \(location.container) = \(location.container)"
                        : "if let \(container) = \(container)"
                    try! IfExprSyntax(header) {
                        for syntax in idetifierDecodingSyntax {
                            syntax
                        }
                    }
                } else {
                    for syntax in idetifierDecodingSyntax {
                        syntax
                    }
                }
            }
            self.unmatchedErrorSyntax(from: decoder)
        }
    }

    /// Determines the container type for identifier decoding.
    ///
    /// Creates a `KeyedDecodingContainer` type with the appropriate coding keys.
    /// If the identifier type is optional or not specified, wraps the container
    /// type in an optional to handle cases where the identifier might be missing.
    ///
    /// - Returns: The container type syntax, optionally wrapped if identifier
    ///   type allows for missing values.
    private func identifierContainerType() -> TypeSyntax {
        let type: TypeSyntax = "KeyedDecodingContainer<\(codingKeys.typeName)>"
        guard identifierType?.isOptionalTypeSyntax ?? true else { return type }
        return TypeSyntax(OptionalTypeSyntax(wrappedType: type))
    }

    /// Creates an identifier variable and its associated key path.
    ///
    /// Constructs a property variable for the enum identifier with the specified
    /// type and applies the variable builder transformation. If no explicit
    /// identifier type is set, wraps the variable with default value handling
    /// to gracefully handle missing or invalid identifiers by defaulting to `nil`.
    ///
    /// - Parameters:
    ///   - identifier: The identifier token name for the variable.
    ///   - type: The type syntax for the identifier variable.
    ///   - context: The macro expansion context.
    ///
    /// - Returns: A tuple containing the configured property variable and its
    ///   associated key path for coding operations.
    private func identifierVariableAndKey(
        _ identifier: TokenSyntax, withType type: TypeSyntax,
        context: some MacroExpansionContext
    ) -> (AnyPropertyVariable<AnyRequiredVariableInitialization>, PathKey) {
        let variable = BasicPropertyVariable(
            name: identifier, type: type, value: nil,
            decodePrefix: "", encodePrefix: "",
            decode: true, encode: true
        )
        let input = Registration(decl: decl, key: keyPath, variable: variable)
        let output = variableBuilder(input)

        guard self.identifierType == nil
        else { return (output.variable.any, output.key) }

        let outVariable = DefaultValueVariable(
            base: output.variable,
            options: .init(onMissingExpr: "nil", onErrorExpr: "nil")
        ).any
        return (outVariable, output.key)
    }

    /// Provides the syntax for encoding at the provided location and encoder.
    ///
    /// The generated implementation encodes the identifier variable to provided
    /// location, the the content of variable encoded to provided `encoder`.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///   - encoder: The encoder content will be encoded to.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation,
        contentAt encoder: TokenSyntax
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return CodeBlockItemListSyntax {
            encodingNode.encoding(
                in: context, to: .withCoder(coder, keyType: location.keyType)
            ).combined()
            let switchExpr = self.encodeSwitchExpression(
                over: location.selfValue, at: location, from: encoder,
                in: context, withDefaultCase: location.hasDefaultCase
            ) { name in
                let container = variable.encodeContainer
                let (variable, key) = identifierVariableAndKey(
                    name, withType: "_", context: context
                )
                let encodingKey = codingKeys.add(
                    keys: key.encoding, field: identifier, context: context
                ).last!.expr
                return variable.encoding(
                    in: context,
                    to: .container(container, key: encodingKey, method: nil)
                )
            }
            if let switchExpr = switchExpr {
                switchExpr
            }
        }
    }
}

extension Registration
where Var: AdjacentlyTaggableSwitcher, Decl: AttributableDeclSyntax {
    /// Checks if enum declares adjacent tagging.
    ///
    /// Checks if enum-case content path provided with `CodedAt` macro.
    ///
    /// - Parameters:
    ///   - contentDecoder: The mapped name for decoder.
    ///   - contentEncoder: The mapped name for encoder.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Variable registration with adjacent tagging data if exists.
    func checkForAdjacentTagging(
        contentDecoder: TokenSyntax, contentEncoder: TokenSyntax,
        codingKeys: CodingKeysMap, context: MacroExpansionContext
    ) -> Registration<Decl, Key, AnyEnumSwitcher> {
        guard
            let attr = ContentAt(from: decl),
            case let keys = attr.keyPath(withExisting: []),
            !keys.isEmpty,
            case let keyPath = PathKey(decoding: keys, encoding: keys)
        else { return self.updating(with: variable.any) }
        let variable = AdjacentlyTaggedEnumSwitcher(
            base: variable,
            contentDecoder: contentDecoder, contentEncoder: contentEncoder,
            keyPath: keyPath, codingKeys: codingKeys, context: context
        )
        return self.updating(with: variable.any)
    }
}
