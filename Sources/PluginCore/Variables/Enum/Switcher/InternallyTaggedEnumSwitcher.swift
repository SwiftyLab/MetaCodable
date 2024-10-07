import SwiftSyntax
import SwiftSyntaxMacros

/// An `EnumSwitcherVariable` generating switch expression for internally
/// tagged enums.
///
/// Provides callback to enum cases for variation data decoding/encoding.
/// The generated switch expression compares case value with the decoded
/// identifier.
struct InternallyTaggedEnumSwitcher<Variable>: TaggedEnumSwitcherVariable
where Variable: PropertyVariable {
    /// The identifier variable build action type.
    ///
    /// Used to build the identifier data and pass in encoding callback.
    typealias VariableBuilder = (
        PathRegistration<EnumDeclSyntax, BasicPropertyVariable>
    ) -> PathRegistration<EnumDeclSyntax, Variable>
    /// The container for case variation encoding.
    ///
    /// This is used in the generated code as the container
    /// for case variation data from the callback to be encoded.
    let encodeContainer: TokenSyntax
    /// The identifier name to use.
    ///
    /// This is used as identifier variable name in generated code.
    let identifier: TokenSyntax
    /// The identifier type to use.
    ///
    /// This is used as identifier variable type in generated code.
    let identifierType: TypeSyntax
    /// The declaration for which code generated.
    ///
    /// This declaration is used for additional attributes data
    /// for customizing generated code.
    let decl: EnumDeclSyntax
    /// The key path at which identifier variable is registered.
    ///
    /// Identifier variable is registered with this path at `node`
    /// during initialization. This path is used for encode callback
    /// provided to enum-cases.
    let keys: [CodingKeysMap.Key]
    /// The node at which identifier variable is registered.
    ///
    /// Identifier variable is registered with the path at this node
    /// during initialization. This node is used to generate identifier
    /// variable decoding/encoding implementations.
    var node: PropertyVariableTreeNode
    /// The builder action for building identifier variable.
    ///
    /// This builder action is used to create and use identifier variable
    /// data to be passed to enum-cases encoding callback.
    let variableBuilder: VariableBuilder

    /// Creates switcher variable with provided data.
    ///
    /// - Parameters:
    ///   - encodeContainer: The container for case variation encoding.
    ///   - identifier: The identifier name to use.
    ///   - identifierType: The identifier type to use.
    ///   - node: The node at which identifier variable is registered.
    ///   - keys: The key path at which identifier variable is registered.
    ///   - decl: The declaration for which code generated.
    ///   - variableBuilder: The builder action for building identifier.
    init(
        encodeContainer: TokenSyntax,
        identifier: TokenSyntax, identifierType: TypeSyntax,
        node: PropertyVariableTreeNode, keys: [CodingKeysMap.Key],
        decl: EnumDeclSyntax, variableBuilder: @escaping VariableBuilder
    ) {
        self.encodeContainer = encodeContainer
        self.identifier = identifier
        self.identifierType = identifierType
        self.decl = decl
        self.node = node
        self.keys = keys
        self.variableBuilder = variableBuilder
    }

    /// Creates switcher variable with provided data.
    ///
    /// - Parameters:
    ///   - encodeContainer: The container for case variation encoding.
    ///   - identifier: The identifier name to use.
    ///   - identifierType: The identifier type to use.
    ///   - keyPath: The key path at which identifier variable is registered.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - decl: The declaration for which code generated.
    ///   - context: The context in which to perform the macro expansion.
    ///   - variableBuilder: The builder action for building identifier.
    init(
        encodeContainer: TokenSyntax,
        identifier: TokenSyntax, identifierType: TypeSyntax,
        keyPath: [String], codingKeys: CodingKeysMap,
        decl: EnumDeclSyntax, context: some MacroExpansionContext,
        variableBuilder: @escaping VariableBuilder
    ) {
        precondition(!keyPath.isEmpty)
        self.encodeContainer = encodeContainer
        self.identifier = identifier
        self.identifierType = identifierType
        self.decl = decl
        self.variableBuilder = variableBuilder
        var node = PropertyVariableTreeNode()
        let variable = BasicPropertyVariable(
            name: identifier, type: self.identifierType, value: nil,
            decodePrefix: "", encodePrefix: "",
            decode: true, encode: true
        )
        let input = Registration(decl: decl, key: keyPath, variable: variable)
        let output = variableBuilder(input)
        let key = output.key
        let field = self.identifier
        self.keys = codingKeys.add(keys: key, field: field, context: context)
        let containerVariable = ContainerVariable(
            encodeContainer: encodeContainer, base: output.variable
        )
        node.register(
            variable: containerVariable, keyPath: keys,
            immutableEncodeContainer: true
        )
        self.node = node
    }

    /// Create basic identifier variable.
    ///
    /// Builds a basic identifier variable that can be processed by builder
    /// action to be passed to enum-case encoding callback.
    ///
    /// - Parameter name: The variable name to use.
    /// - Returns: The basic identifier variable.
    func base(_ name: TokenSyntax) -> BasicPropertyVariable {
        return BasicPropertyVariable(
            name: name, type: self.identifierType, value: nil,
            decodePrefix: "", encodePrefix: "",
            decode: true, encode: true
        )
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
        return .init()
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
        return .raw(!values.isEmpty ? values : ["\(literal: name)"])
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
        return []
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
        /// The container for case variation encoding.
        ///
        /// This is used in the generated code as the container
        /// for case variation data from the callback to be encoded.
        let encodeContainer: TokenSyntax
        /// The value wrapped by this instance.
        ///
        /// The wrapped variable's type data is
        /// preserved and this variable is used
        /// to chain code generation implementations.
        let base: Wrapped

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
            return switch location {
            case .coder(let encoder, _):
                fatalError("Error encoding \(Self.self) to \(encoder)")
            case .container(let container, _, _):
                "var \(self.encodeContainer) = \(container)"
            }
        }
    }
}
