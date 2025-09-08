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
        AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isEnum || isProtocol,
                AggregatedDiagnosticProducer {
                    mustBeCombined(with: Codable.self)
                    cantBeCombined(with: UnTagged.self)
                    cantBeCombined(with: DecodedAt.self)
                    cantBeCombined(with: EncodedAt.self)
                },
                else: AggregatedDiagnosticProducer {
                    attachedToUngroupedVariable()
                    attachedToNonStaticVariable()
                    cantBeCombined(with: DecodedAt.self)
                    cantBeCombined(with: EncodedAt.self)
                    cantBeCombined(with: CodedIn.self)
                    cantBeCombined(with: IgnoreCoding.self)
                }
            )
        }
    }
}

extension Registration
where Var == ExternallyTaggedEnumSwitcher, Decl == EnumDeclSyntax {
    /// Checks if enum declares internal tagging and creates appropriate switcher.
    ///
    /// Examines the enum declaration for `CodedAt`, `DecodedAt`, and `EncodedAt`
    /// attributes to determine if internal tagging should be used. Internal tagging
    /// occurs when these attributes specify non-empty key paths that indicate where
    /// the type identifier should be located within the encoded structure.
    ///
    /// If valid key paths are found, creates an `InternallyTaggedEnumSwitcher` with
    /// the specified configuration. The identifier type is determined from the `CodedAs`
    /// attribute if present, otherwise defaults to `String`.
    ///
    /// - Parameters:
    ///   - container: The container token for case variation encoding/decoding.
    ///   - identifier: The identifier token name to use for tagging.
    ///   - codingKeys: The coding keys map for key path resolution.
    ///   - forceDecodingReturn: Whether to force explicit `return` statements in
    ///     generated decoding switch cases. When `true`, each case will include a
    ///     `return` statement after assignment for early exit.
    ///   - context: The macro expansion context for diagnostics and code generation.
    ///   - variableBuilder: Builder function for creating the identifier variable
    ///     from the basic property variable registration.
    ///   - switcherBuilder: Builder function for creating the final switcher from
    ///     the internally tagged enum switcher registration.
    ///
    /// - Returns: A type-erased enum switcher registration. If internal tagging
    ///   is detected (non-empty decode and encode paths), returns the result of
    ///   applying both builder functions. Otherwise, returns the current registration
    ///   with a type-erased variable, indicating external tagging should be used.
    func checkForInternalTagging<Variable, Switcher>(
        container: TokenSyntax, identifier: TokenSyntax,
        codingKeys: CodingKeysMap, forceDecodingReturn: Bool,
        context: some MacroExpansionContext,
        variableBuilder: @escaping (
            PathRegistration<EnumDeclSyntax, BasicPropertyVariable>
        ) -> PathRegistration<EnumDeclSyntax, Variable>,
        switcherBuilder: @escaping (
            Registration<Decl, Key, InternallyTaggedEnumSwitcher<Variable>>
        ) -> Registration<Decl, Key, Switcher>
    ) -> Registration<Decl, Key, AnyEnumSwitcher>
    where Variable: PropertyVariable, Switcher: EnumSwitcherVariable {
        let tagAttr = CodedAt(from: decl)
        let decodeTagAttr = DecodedAt(from: decl)
        let encodeTagAttr = EncodedAt(from: decl)
        let path = tagAttr?.keyPath(withExisting: []) ?? []
        let decodedPath = decodeTagAttr?.keyPath(withExisting: path) ?? path
        let encodedPath = encodeTagAttr?.keyPath(withExisting: path) ?? path

        guard
            !decodedPath.isEmpty && !encodedPath.isEmpty
        else { return self.updating(with: variable.any) }
        let typeAttr = CodedAs(from: decl)
        let keyPath = PathKey(decoding: decodedPath, encoding: encodedPath)
        let variable = InternallyTaggedEnumSwitcher(
            identifierDecodeContainer: container,
            identifierEncodeContainer: container,
            identifier: identifier, identifierType: typeAttr?.type,
            keyPath: keyPath, codingKeys: codingKeys,
            decl: decl, context: context,
            forceDecodingReturn: forceDecodingReturn,
            variableBuilder: variableBuilder
        )

        let newRegistration = switcherBuilder(self.updating(with: variable))
        return newRegistration.updating(with: newRegistration.variable.any)
    }
}
