import OrderedCollections
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `CodedAs` macro-attribute.
///
/// This type can validate`CodedAs` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct CodedAs: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The alternate value expression provided.
    var exprs: [ExprSyntax] {
        return node.arguments?
            .as(LabeledExprListSyntax.self)?.map(\.expression) ?? []
    }

    /// The type to which to be decoded/encoded.
    ///
    /// Used for enums with internal/adjacent tagging to decode
    /// the identifier to this type.
    var type: TypeSyntax? {
        return node.attributeName.as(IdentifierTypeSyntax.self)?
            .genericArgumentClause?.arguments.first?.argument
    }

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
    /// * If macro has zero arguments provided:
    ///   * Attached declaration is an enum/protocol declaration.
    ///   * This attribute must be combined with `Codable`
    ///   and `CodedAt` attribute.
    /// * If macro has one argument provided:
    ///   * Attached declaration is an enum-case or variable declaration.
    ///   * This attribute isn't used combined with `IgnoreCoding`
    ///     attribute.
    /// * If macro attached declaration is variable declaration:
    ///   * Attached declaration is not a grouped variable declaration.
    ///   * Attached declaration is not a static variable declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                has(arguments: 0),
                AggregatedDiagnosticProducer {
                    expect(
                        syntaxes: EnumDeclSyntax.self, ProtocolDeclSyntax.self
                    )
                    mustBeCombined(with: Codable.self)
                    mustBeCombined(with: CodedAt.self)
                },
                else: `if`(
                    isVariable,
                    AggregatedDiagnosticProducer {
                        attachedToUngroupedVariable()
                        attachedToNonStaticVariable()
                        cantBeCombined(with: IgnoreCoding.self)
                    },
                    else: AggregatedDiagnosticProducer {
                        expect(
                            syntaxes: EnumCaseDeclSyntax.self,
                            VariableDeclSyntax.self
                        )
                        cantBeCombined(with: IgnoreCoding.self)
                    }
                )
            )
        }
    }
}

extension CodedAs: KeyPathProvider {
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

extension Registration where Key == [ExprSyntax], Decl: AttributableDeclSyntax {
    /// Update registration with alternate value expression data.
    ///
    /// New registration is updated with value expression data that will be
    /// used for decoding/encoding, if provided and registration doesn't
    /// already have a value.
    ///
    /// - Returns: Newly built registration with value expression data.
    func checkForAlternateValue() -> Self {
        guard
            self.key.isEmpty,
            let attr = CodedAs(from: self.decl)
        else { return self }
        return self.updating(with: attr.exprs)
    }
}

extension Registration
where Key == [String], Decl: AttributableDeclSyntax, Var: PropertyVariable {
    /// Update registration with alternate `CodingKey`s data.
    ///
    /// New registration is updated with `CodingKey`s data that will be
    /// used for decoding/encoding, if provided.
    ///
    /// - Parameters:
    ///   - codingKeys: The `CodingKeys` map new data will be added.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns:  Newly built registration with additional `CodingKey`s data.
    func checkForAlternateKeyValues(
        addTo codingKeys: CodingKeysMap,
        context: some MacroExpansionContext
    ) -> Registration<Decl, Key, AnyPropertyVariable<Var.Initialization>> {
        guard
            let attr = CodedAs(from: self.decl),
            case let path = attr.providedPath,
            !path.isEmpty
        else { return self.updating(with: self.variable.any) }
        let keys = OrderedSet(codingKeys.add(keys: path, context: context))
        let oldVar = self.variable
        let newVar = AliasedPropertyVariable(base: oldVar, additionalKeys: keys)
        return self.updating(with: newVar.any)
    }
}
