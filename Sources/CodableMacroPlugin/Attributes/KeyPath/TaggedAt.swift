@_implementationOnly import SwiftDiagnostics
@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// Attribute type for `TaggedAt` macro-attribute.
///
/// This type can validate`TaggedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct TaggedAt: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// Creates a new instance with the provided node.
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax) {
        guard
            node.attributeName.as(IdentifierTypeSyntax.self)!
                .name.text == Self.name
        else { return nil }
        self.node = node
    }

    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// The following conditions are checked by the
    /// built diagnoser:
    /// * Attached declaration is an enum declaration.
    /// * Macro should be used in presence of `Codable`.
    /// * Macro usage is not duplicated for the same
    ///   declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(syntaxes: EnumDeclSyntax.self)
            mustBeCombined(with: Codable.self)
            cantDuplicate()
        }
    }
}

extension TaggedAt: KeyPathProvider {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// Always `true` for this type.
    var provided: Bool { true }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path overrides current `CodingKey` path data.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String] { providedPath }
}

extension Registration
where Var == ExternallyTaggedEnumSwitcher, Decl == EnumDeclSyntax {
    /// Checks if enum declares internal tagging.
    ///
    /// Checks if identifier path provided with `TaggedAt` macro,
    /// identifier type is used if `CodedAs` macro provided falling back to
    /// the `fallbackType` passed.
    ///
    /// - Parameters:
    ///   - encodeContainer: The container for case variation encoding.
    ///   - identifier: The identifier name to use.
    ///   - fallbackType: The fallback identifier type to use if not provided.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///   - variableBuilder: The builder action for building identifier.
    ///   - switcherBuilder: The further builder action if check succeeds.
    ///
    /// - Returns: Type-erased variable registration applying builders
    ///   if succeeds, otherwise current variable type-erased registration.
    func checkForInternalTagging<Variable, Switcher>(
        encodeContainer: TokenSyntax,
        identifier: TokenSyntax, fallbackType: TypeSyntax,
        codingKeys: CodingKeysMap, context: some MacroExpansionContext,
        variableBuilder: @escaping (
            PathRegistration<EnumDeclSyntax, BasicPropertyVariable>
        ) -> PathRegistration<EnumDeclSyntax, Variable>,
        switcherBuilder: @escaping (
            Registration<Decl, Key, InternallyTaggedEnumSwitcher<Variable>>
        ) -> Registration<Decl, Key, Switcher>
    ) -> Registration<Decl, Key, AnyEnumSwitcher>
    where Variable: PropertyVariable, Switcher: EnumSwitcherVariable {
        guard
            let tagAttr = TaggedAt(from: decl)
        else { return self.updating(with: variable.any) }
        let typeAttr = CodedAs(from: decl)
        let variable = InternallyTaggedEnumSwitcher(
            encodeContainer: encodeContainer, identifier: identifier,
            identifierType: typeAttr?.type ?? fallbackType,
            keyPath: tagAttr.keyPath(withExisting: []), codingKeys: codingKeys,
            decl: decl, context: context, variableBuilder: variableBuilder
        )
        let newRegistration = switcherBuilder(self.updating(with: variable))
        return newRegistration.updating(with: newRegistration.variable.any)
    }
}
