import OrderedCollections
import SwiftSyntax
import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance
/// for a group of properties.
///
/// This type can be used for types like `struct`s and `class`es
/// for `Codable` conformance implementation.
struct MemberGroup<Decl>: TypeVariable, InitializableVariable
where
    Decl: MemberGroupSyntax & GenericTypeDeclSyntax & AttributableDeclSyntax,
    Decl.MemberSyntax: VariableSyntax, Decl.MemberSyntax.Variable: NamedVariable
{
    /// The declaration members syntax type.
    typealias MemberSyntax = Decl.MemberSyntax

    /// The where clause generator for generic type arguments.
    let constraintGenerator: ConstraintGenerator
    /// The root node containing all the keys and associated field metadata maps for decoding.
    let decodingNode: PropertyVariableTreeNode
    /// The root node containing all the keys and associated field metadata maps for encoding.
    let encodingNode: PropertyVariableTreeNode
    /// The `CodingKeys` map containing keys
    /// and generated case names.
    let codingKeys: CodingKeysMap

    /// Creates a new member group from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - builder: The builder action to use to update member variables
    ///     registration data.
    ///
    /// - Returns: Created member group.
    init<Output: PropertyVariable>(
        from decl: Decl, in context: some MacroExpansionContext,
        codingKeys: CodingKeysMap, memberInput: Decl.ChildSyntaxInput,
        builder: (
            _ input: PathRegistration<MemberSyntax, MemberSyntax.Variable>
        ) -> PathRegistration<MemberSyntax, Output>
    ) {
        self.constraintGenerator = .init(decl: decl)
        var decodingNode = PropertyVariableTreeNode()
        var encodingNode = PropertyVariableTreeNode()
        for member in decl.codableMembers(input: memberInput) {
            let `var` = member.codableVariable(in: context)
            let path = [CodingKeysMap.Key.name(for: `var`.name).text]
            let key = PathKey(decoding: path, encoding: path)
            let reg = Registration(decl: member, key: key, context: context)
            let registration = builder(reg)
            let variable = registration.variable
            let decodingPath = registration.key.decoding
            let encodingPath = registration.key.encoding
            let name = variable.name

            // Register in the appropriate node based on decode/encode flags
            if variable.decode ?? true {
                let keys = codingKeys.add(
                    keys: decodingPath, field: name, context: context)
                decodingNode.register(variable: variable, keyPath: keys)
            }

            if variable.encode ?? true {
                let keys = codingKeys.add(
                    keys: encodingPath, field: name, context: context)
                encodingNode.register(variable: variable, keyPath: keys)
            }
        }
        self.decodingNode = decodingNode
        self.encodingNode = encodingNode
        self.codingKeys = codingKeys
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// If conformance type provided is `nil` no expansion performed.
    /// Otherwise, variables registered are decoded based on registered data.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard let conformance = location.conformance else { return nil }
        let syntax = CodeBlockItemListSyntax {
            let nLocation = PropertyVariableTreeNode.CodingLocation.withCoder(
                location.method.arg, keyType: codingKeys.type
            )
            decodingNode.decoding(in: context, from: nLocation).combined()
            nLocation.decoding(in: context)
        }
        return .init(
            code: syntax, modifiers: [],
            whereClause: constraintGenerator.decodingClause(
                withVariables: decodingNode.linkedVariables,
                conformingTo: conformance
            ),
            inheritanceClause: .init { .init(type: conformance) }
        )
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// If conformance type provided is `nil` no expansion performed.
    /// Otherwise, variables registered are encoded based on registered data.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard let conformance = location.conformance else { return nil }
        let syntax = CodeBlockItemListSyntax {
            let nLocation = PropertyVariableTreeNode.CodingLocation.withCoder(
                location.method.arg, keyType: codingKeys.type
            )
            encodingNode.encoding(in: context, to: nLocation).combined()
            nLocation.encoding(in: context)
        }
        return .init(
            code: syntax, modifiers: [],
            whereClause: constraintGenerator.encodingClause(
                withVariables: encodingNode.linkedVariables,
                conformingTo: conformance
            ),
            inheritanceClause: .init { .init(type: conformance) }
        )
    }

    /// Provides the syntax for `CodingKeys` declarations.
    ///
    /// Single `CodingKeys` enum generated using the `codingKeys`
    /// provided during initialization.
    ///
    /// - Parameters:
    ///   - protocols: The protocols for which conformance generated.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The `CodingKeys` declarations.
    func codingKeys(
        confirmingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        guard
            !self.protocols(
                named: TypeCodingLocation.Method.decode().protocol,
                TypeCodingLocation.Method.encode.protocol,
                in: protocols
            ).isEmpty,
            let decl = codingKeys.decl(in: context)
        else { return [] }
        return MemberBlockItemListSyntax { decl }
    }

    /// Indicates the initialization type for this variable.
    ///
    /// Initialization data of individual variables registered are provided.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> [AnyInitialization] {
        // Combine variables from both nodes for initialization
        let decodingVars = decodingNode.linkedVariables
        let encodingVars = encodingNode.linkedVariables

        // Create a dictionary to deduplicate variables by name
        var variableDict: OrderedDictionary<TokenSyntax, any PropertyVariable> =
            [:]
        for variable in (decodingVars + encodingVars)
        where variableDict[variable.name] == nil {
            variableDict[variable.name] = variable
        }

        return variableDict.values.map { $0.initializing(in: context).any }
    }
}

extension MemberGroup: DeclaredVariable
where Decl.ChildSyntaxInput == Void, Decl.MemberSyntax == PropertyDeclSyntax {
    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses default builder actions that provides following features:
    /// * `CodingKeys` case style customization.
    /// * Initialized variables decoding/encoding ignore customization.
    /// * `CodingKeys` path customization for individual variables.
    /// * Multiple `CodingKeys` alias customization for individual variables.
    /// * Helper expression with custom decoding/encoding customization.
    /// * Default expression when decoding failure customization.
    /// * Individual variables decoding/encoding ignore customization.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    ///
    /// - Returns: Created member group.
    init(from decl: Decl, in context: some MacroExpansionContext) {
        let codingKeys = CodingKeysMap(typeName: "CodingKeys")
        self.init(
            from: decl, in: context,
            codingKeys: codingKeys, memberInput: ()
        ) { input in
            input
                .transformKeysAccordingToStrategy(attachedTo: decl)
                .checkInitializedCodingIgnored(attachedAt: decl)
                .registerKeyPath(
                    provider: CodedAt(from: input.decl)
                        ?? CodedIn(from: input.decl) ?? CodedIn(),
                    forDecoding: DecodedAt(from: input.decl),
                    forEncoding: EncodedAt(from: input.decl)
                )
                .detectCommonStrategies(from: decl)
                .useHelperCoderIfExists()
                .checkForAlternateKeyValues(addTo: codingKeys, context: context)
                .addDefaultValueIfExists()
                .checkCanBeInitialized()
                .checkCodingIgnored()
        }
    }
}
