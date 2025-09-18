import SwiftSyntax
import SwiftSyntaxMacros

/// An `EnumSwitcherVariable` generating switch expression for internally
/// tagged enums.
///
/// Provides callback to enum cases for variation data decoding/encoding.
/// The generated switch expression compares case value with the decoded
/// identifier.
struct InternallyTaggedEnumSwitcher<Variable>: TaggedEnumSwitcherVariable
where
    Variable: PropertyVariable,
    Variable.Initialization == RequiredInitialization
{
    /// The identifier variable build action type.
    ///
    /// Used to build the identifier data and pass in encoding callback.
    typealias VariableBuilder = (
        PathRegistration<EnumDeclSyntax, BasicPropertyVariable>
    ) -> PathRegistration<EnumDeclSyntax, Variable>
    /// The identifier name to use.
    ///
    /// This is used as identifier variable name in generated code.
    let identifier: TokenSyntax
    /// The identifier type to use.
    ///
    /// This is used as identifier variable type in generated code.
    let identifierType: TypeSyntax?
    /// The declaration for which code generated.
    ///
    /// This declaration is used for additional attributes data
    /// for customizing generated code.
    let decl: EnumDeclSyntax
    /// The node at which identifier variable is registered for decoding.
    ///
    /// Identifier variable is registered with the path at this node
    /// during initialization. This node is used to generate identifier
    /// variable decoding implementations.
    var decodingNode: PropertyVariableTreeNode
    /// The node at which identifier variable is registered for encoding.
    ///
    /// Identifier variable is registered with the path at this node
    /// during initialization. This node is used to generate identifier
    /// variable encoding implementations.
    var encodingNode: PropertyVariableTreeNode
    /// The coding keys map for managing key path resolution and generation.
    ///
    /// Maintains the mapping between field names and their corresponding coding keys,
    /// enabling proper key path resolution during encoding and decoding operations.
    /// Used to generate and track coding keys for the identifier variable registration.
    var codingKeys: CodingKeysMap
    /// The key path configuration for identifier variable registration.
    ///
    /// Defines the separate decoding and encoding paths where the identifier variable
    /// should be registered. Both paths must be non-empty for internal tagging to work.
    /// The paths determine the exact location in the coding structure where the
    /// identifier will be read from during decoding and written to during encoding.
    let keyPath: PathKey
    /// The builder action for building identifier variable.
    ///
    /// This builder action is used to create and use identifier variable
    /// data to be passed to enum-cases encoding callback.
    let variableBuilder: VariableBuilder
    /// The container variable that manages encoding/decoding container exposure.
    ///
    /// Wraps the identifier variable with container management functionality,
    /// exposing both decoding and encoding containers through named variables.
    /// This variable handles the container assignment and provides the interface
    /// for accessing containers during the coding process.
    let variable: ContainerVariable<Variable>
    /// Whether to force explicit `return` statements in generated decoding switch cases.
    ///
    /// When `true`, each enum case in the generated decoding switch statement will include
    /// an explicit `return` statement after the case assignment (`self = .case(...)`).
    /// This provides early exit from the switch and can help with code clarity and
    /// potential compiler optimizations.
    ///
    /// When `false`, the switch cases rely on implicit fallthrough behavior without
    /// explicit return statements, which is the traditional approach.
    ///
    /// This flag is typically set based on the code generation strategy or specific
    /// requirements for the generated decoding implementation.
    let forceDecodingReturn: Bool

    /// Creates an internally tagged enum switcher and configures all components.
    ///
    /// This is the primary initializer that sets up the complete internally tagged enum
    /// switcher from scratch. It creates the decoding/encoding nodes, registers the
    /// identifier variable at the specified key paths, and configures the container
    /// variable with the provided container names.
    ///
    /// - Parameters:
    ///   - identifierDecodeContainer: The token name for the decoding container variable
    ///     that will be exposed during decoding operations.
    ///   - identifierEncodeContainer: The token name for the encoding container variable
    ///     that will be exposed during encoding operations.
    ///   - identifier: The identifier token name for the enum case identifier variable.
    ///   - identifierType: The optional type syntax for the identifier variable. If nil,
    ///     default fallback handling with nil values will be applied.
    ///   - keyPath: The key path configuration with non-empty decoding and encoding paths
    ///     where the identifier variable will be registered.
    ///   - codingKeys: The coding keys map for managing key generation and resolution.
    ///   - decl: The enum declaration syntax for which code is being generated.
    ///   - context: The macro expansion context for key generation and validation.
    ///   - forceDecodingReturn: Whether to force explicit `return` statements in generated
    ///     decoding switch cases. When `true`, each case includes a `return` after assignment
    ///     for early exit from the switch statement.
    ///   - variableBuilder: The builder function for transforming the basic property
    ///     variable into the final variable type with custom processing.
    init(
        identifierDecodeContainer: TokenSyntax,
        identifierEncodeContainer: TokenSyntax,
        identifier: TokenSyntax, identifierType: TypeSyntax?,
        keyPath: PathKey, codingKeys: CodingKeysMap,
        decl: EnumDeclSyntax, context: some MacroExpansionContext,
        forceDecodingReturn: Bool,
        variableBuilder: @escaping VariableBuilder
    ) {
        precondition(!keyPath.decoding.isEmpty && !keyPath.encoding.isEmpty)
        self.identifier = identifier
        self.identifierType = identifierType
        self.decl = decl
        self.variableBuilder = variableBuilder
        self.forceDecodingReturn = forceDecodingReturn

        var decodingNode = PropertyVariableTreeNode()
        var encodingNode = PropertyVariableTreeNode()

        let variable = BasicPropertyVariable(
            name: identifier, type: "_", value: nil,
            decodePrefix: "", encodePrefix: "",
            decode: true, encode: true
        )
        let input = Registration(decl: decl, key: keyPath, variable: variable)
        let output = variableBuilder(input)
        let key = output.key
        let field = self.identifier

        // Get separate keys for decoding and encoding
        let decodingKeys = codingKeys.add(
            keys: key.decoding, field: field, context: context
        )
        let encodingKeys = codingKeys.add(
            keys: key.encoding, field: field, context: context
        )

        self.variable = ContainerVariable(
            decodeContainer: identifierDecodeContainer,
            encodeContainer: identifierEncodeContainer,
            base: output.variable, providedType: identifierType
        )

        // Register for decoding using decodingKeys
        decodingNode.register(
            variable: self.variable, keyPath: decodingKeys,
            immutableEncodeContainer: true
        )

        // Register for encoding using encodingKeys
        encodingNode.register(
            variable: self.variable, keyPath: encodingKeys,
            immutableEncodeContainer: true
        )

        self.decodingNode = decodingNode
        self.encodingNode = encodingNode
        self.codingKeys = codingKeys
        self.keyPath = keyPath
    }

    /// Provides node at which case associated variables are registered.
    ///
    /// Creates a new node for each invocation, allowing separate registration
    /// for each case associated variables.
    ///
    /// - Parameters:
    ///   - decl: The declaration for which to provide.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The registering node.
    func node(
        for decl: EnumCaseVariableDeclSyntax,
        in context: some MacroExpansionContext
    ) -> PropertyVariableTreeNode {
        .init()
    }

    /// Creates value expressions for provided enum-case variable.
    ///
    /// If value expressions are explicitly provided then those are used,
    /// otherwise case name as `String` literal used as value.
    ///
    /// - Parameters:
    ///   - variable: The variable for which generated.
    ///   - values: The values present in syntax.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated value.
    func keyExpression<Var>(
        for variable: Var, values: [ExprSyntax],
        codingKeys: CodingKeysMap, context: some MacroExpansionContext
    ) -> EnumVariable.CaseValue where Var: EnumCaseVariable {
        let name = CodingKeysMap.Key.name(for: variable.name).text
        return !values.isEmpty
            ? .raw(
                values.map { expr in
                    .from(
                        expression: expr, inheritedType: identifierType,
                        context: context
                    )
                })
            : .raw([.init(syntax: "\(literal: name)", type: .string)])
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// The generated implementation decodes the identifier variable from type
    /// and builder action data, the decoder identifier then compared against
    /// each case value.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return self.decoding(in: context, from: location, contentAt: coder)
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// The generated implementation passes container in callback for
    /// enum-case implementation to generate value encoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return self.encoding(in: context, to: location, contentAt: coder)
    }

    /// Creates additional enum declarations for enum variable.
    ///
    /// No extra `CodingKeys` added by this variable.
    ///
    /// - Parameter context: The macro expansion context.
    /// - Returns: The generated enum declaration syntax.
    func codingKeys(
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        []
    }
}

extension InternallyTaggedEnumSwitcher {
    /// A variable value exposing encoding container.
    ///
    /// The `ContainerVariable` forwards decoding implementation
    /// to underlying variable while exposing encoding container via variable
    /// provided with `encodeContainer` name.
    struct ContainerVariable<Wrapped>: PropertyVariable, ComposedVariable
    where Wrapped: PropertyVariable {
        /// The initialization type of this variable.
        ///
        /// Initialization type is the same as underlying wrapped variable.
        typealias Initialization = Wrapped.Initialization
        /// The mapped name for decoder.
        ///
        /// The decoder at location passed will be exposed
        /// with this variable name.
        let decodeContainer: TokenSyntax
        /// The mapped name for encoder.
        ///
        /// The encoder at location passed will be exposed
        /// with this variable name.
        let encodeContainer: TokenSyntax
        /// The value wrapped by this instance.
        ///
        /// The wrapped variable's type data is
        /// preserved and this variable is used
        /// to chain code generation implementations.
        let base: Wrapped
        /// The optional type syntax provided for the container.
        ///
        /// When specified, this type determines the container's optionality behavior
        /// during decoding. If the type is optional, missing containers are handled
        /// gracefully. If non-optional or nil, different fallback strategies apply.
        let providedType: TypeSyntax?

        /// Whether the variable is to be decoded.
        ///
        /// This variable is always set as to be decoded.
        var decode: Bool? { true }
        /// Whether the variable is to be encoded.
        ///
        /// This variable is always set as to be encoded.
        var encode: Bool? { true }

        /// Whether the variable type requires `Decodable` conformance.
        ///
        /// This variable never requires `Decodable` conformance
        var requireDecodable: Bool? { false }
        /// Whether the variable type requires `Encodable` conformance.
        ///
        /// This variable never requires `Encodable` conformance
        var requireEncodable: Bool? { false }

        /// The fallback strategy used when decoding fails or data is missing.
        ///
        /// Determines how to handle decoding failures based on the provided type:
        /// - When `providedType` is `nil`: Uses `.ifMissing` fallback for both missing
        ///   and error cases, setting the container to `nil`.
        /// - When `providedType` is optional: Uses `.onlyIfMissing` fallback, setting
        ///   the container to `nil` only when data is missing.
        /// - When `providedType` is non-optional: Uses `.throw` strategy, propagating
        ///   decoding errors without fallback handling.
        var decodingFallback: DecodingFallback {
            let containerFallbackSyntax = CodeBlockItemListSyntax {
                "\(decodeContainer) = nil"
            }

            return switch providedType {
            case .none:
                .ifMissing(
                    containerFallbackSyntax, ifError: containerFallbackSyntax
                )
            case .some(let type) where type.isOptionalTypeSyntax == true:
                .onlyIfMissing(containerFallbackSyntax)
            default:
                .throw
            }
        }

        /// Provides the code syntax for decoding this variable
        /// at the provided location.
        ///
        /// Assigns the decoding container passed in location to the variable
        /// created with the `decodeContainer` name provided.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The decoding location for the variable.
        ///
        /// - Returns: The generated variable decoding code.
        func decoding(
            in context: some MacroExpansionContext,
            from location: PropertyCodingLocation
        ) -> CodeBlockItemListSyntax {
            switch location {
            case .coder(let decoder, _):
                fatalError("Error encoding \(Self.self) to \(decoder)")
            case .container(let container, _, _):
                "\(self.decodeContainer) = \(container)"
            }
        }

        /// Provides the code syntax for encoding this variable
        /// at the provided location.
        ///
        /// Assigns the encoding container passed in location to the variable
        /// created with the `encodeContainer` name provided.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The encoding location for the variable.
        ///
        /// - Returns: The generated variable encoding code.
        func encoding(
            in context: some MacroExpansionContext,
            to location: PropertyCodingLocation
        ) -> CodeBlockItemListSyntax {
            switch location {
            case .coder(let encoder, _):
                fatalError("Error encoding \(Self.self) to \(encoder)")
            case .container(let container, _, _):
                "var \(self.encodeContainer) = \(container)"
            }
        }
    }
}
