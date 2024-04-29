import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `CodedAt` macro-attribute.
///
/// This type can validate`CodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct CodedAt: PropertyAttribute {
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
    /// * Macro usage is not duplicated for the same declaration.
    /// * If macro is attached to enum/protocol declaration:
    ///   * This attribute must be combined with `Codable`
    ///     attribute.
    ///   * This attribute isn't used combined with `UnTagged`
    ///     attribute.
    /// * else:
    ///   * Attached declaration is a variable declaration.
    ///   * Attached declaration is not a grouped variable
    ///     declaration.
    ///   * Attached declaration is not a static variable
    ///     declaration.
    ///   * This attribute isn't used combined with `CodedIn`
    ///     and `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isEnum || isProtocol,
                AggregatedDiagnosticProducer {
                    mustBeCombined(with: Codable.self)
                    cantBeCombined(with: UnTagged.self)
                },
                else: AggregatedDiagnosticProducer {
                    attachedToUngroupedVariable()
                    attachedToNonStaticVariable()
                    cantBeCombined(with: CodedIn.self)
                    cantBeCombined(with: IgnoreCoding.self)
                }
            )
        }
    }
}

extension Registration
where Var == ExternallyTaggedEnumSwitcher, Decl == EnumDeclSyntax {
    /// Checks if enum declares internal tagging.
    ///
    /// Checks if identifier path provided with `CodedAt` macro,
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
            let tagAttr = CodedAt(from: decl)
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
