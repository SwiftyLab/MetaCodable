@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance
/// for a group of properties.
///
/// This type can be used for types like `struct`s and `class`es
/// for `Codable` conformance implementation.
struct MemberGroup<Decl>: TypeVariable, InitializableVariable
where
    Decl: MemberGroupSyntax & GenericTypeDeclSyntax & AttributableDeclSyntax,
    Decl.MemberSyntax.Variable: NamedVariable
{
    /// The where clause generator for generic type arguments.
    let constraintGenerator: ConstraintGenerator
    /// The root node containing all the keys
    /// and associated field metadata maps.
    let node: PropertyVariableTreeNode
    /// The case map containing keys
    /// and generated case names.
    let caseMap: CaseMap

    /// Creates a new member group from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - caseMap: The case map where `CodingKeys` maintained.
    ///   - builder: The builder action to use to update member variable registration data.
    ///
    /// - Returns: Created member group.
    init<Output: PropertyVariable>(
        from decl: Decl, in context: some MacroExpansionContext,
        caseMap: CaseMap,
        builder: (
            _ input: Registration<Decl.MemberSyntax, Decl.MemberSyntax.Variable>
        ) -> Registration<Decl.MemberSyntax, Output>
    ) {
        self.constraintGenerator = .init(decl: decl)
        var node = PropertyVariableTreeNode()
        for member in decl.codableMembers() {
            let reg = Registration(declaration: member, context: context)
            let registration = builder(reg)
            let path = registration.keyPath
            let variable = registration.variable
            guard
                (variable.decode ?? true) || (variable.encode ?? true)
            else { continue }
            let name = variable.name
            let keys = caseMap.add(keys: path, field: name, context: context)
            node.register(variable: variable, keyPath: keys)
        }
        self.node = node
        self.caseMap = caseMap
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
        return .init(
            code: node.decoding(
                in: context,
                from: .coder(location.method.arg, keyType: caseMap.type)
            ),
            modifiers: [],
            whereClause: constraintGenerator.decodingClause(
                withVariables: node.linkedVariables,
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
        return .init(
            code: node.encoding(
                in: context,
                to: .coder(location.method.arg, keyType: caseMap.type)
            ),
            modifiers: [],
            whereClause: constraintGenerator.encodingClause(
                withVariables: node.linkedVariables,
                conformingTo: conformance
            ),
            inheritanceClause: .init { .init(type: conformance) }
        )
    }

    /// Provides the syntax for `CodingKeys` declarations.
    ///
    /// Single `CodingKeys` enum generated using the `caseMap`
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
                named: TypeCodingLocation.Method.decode.protocol,
                TypeCodingLocation.Method.encode.protocol,
                in: protocols
            ).isEmpty
        else { return [] }
        return MemberBlockItemListSyntax {
            caseMap.decl(in: context)
        }
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
        return node.linkedVariables.map { $0.initializing(in: context).any }
    }
}

extension MemberGroup: DeclaredVariable
where Decl.MemberSyntax == PropertyDeclSyntax {
    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses default builder actions that provides following features:
    /// * `CodingKeys` case style customization.
    /// * Initialized variables decoding/encoding ignore customization.
    /// * `CodingKeys` path customization for individual variables.
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
        self.init(
            from: decl, in: context,
            caseMap: .init(typeName: "CodingKeys")
        ) { input in
            return
                input
                .transformKeysAccordingToStrategy(attachedTo: decl)
                .checkInitializedCodingIgnored(attachedAt: decl)
                .registerKeyPath(
                    provider: CodedAt(from: input.declaration)
                        ?? CodedIn(from: input.declaration) ?? CodedIn()
                )
                .useHelperCoderIfExists()
                .addDefaultValueIfExists()
                .checkCanBeInitialized()
                .checkCodingIgnored()
        }
    }
}
