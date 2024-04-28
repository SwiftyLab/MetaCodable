import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `UnTagged` macro-attribute.
///
/// This type can validate`UnTagged` macro-attribute usage and
/// extract data for `Codable` macro to generate implementation.
///
/// Attaching this macro to enum declaration indicates the enum doesn't
/// have any identifier for its cases and each case should be tried for decoding
/// until decoding succeeds for a case.
package struct UnTagged: PeerAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// Creates a new instance with the provided node
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
    /// * This attribute must be combined with `Codable` attribute.
    /// * This attribute mustn't be combined with `CodedAt` attribute.
    /// * Attached declaration is an enum-case or variable declaration.
    ///
    /// For enum case declarations this attribute can be attached
    /// without `Codable` macro.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            shouldNotDuplicate()
            mustBeCombined(with: Codable.self)
            cantBeCombined(with: CodedAt.self)
            expect(syntaxes: EnumDeclSyntax.self)
        }
    }
}

extension Registration
where Var: EnumSwitcherVariable, Decl: AttributableDeclSyntax {
    /// Update registration whether enum doesn't have any identifier cases.
    ///
    /// New registration is updated with exhaustive decoding and encoding
    /// approach for enum-cases without any case identifiers.
    ///
    /// - Parameter context: The context in which to perform macro expansion.
    /// - Returns: Newly built registration with updated decoding/encoding
    ///   approach.
    func checkIfUnTagged(
        in context: some MacroExpansionContext
    ) -> Registration<Decl, Key, AnyEnumSwitcher> {
        let attr = UnTagged(from: decl)
        let newVariable: any EnumSwitcherVariable
        if attr != nil {
            let error = context.makeUniqueName("decodingError")
            newVariable = UnTaggedEnumSwitcher(node: .init(), error: error)
        } else {
            newVariable = variable
        }
        return self.updating(with: AnyEnumSwitcher(base: newVariable))
    }
}
