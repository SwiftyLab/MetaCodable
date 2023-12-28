@_implementationOnly import SwiftSyntax

/// Attribute type for `CodedAs` macro-attribute.
///
/// This type can validate`CodedAs` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAs: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The alternate value expression provided.
    var expr: ExprSyntax? {
        return node.arguments?
            .as(LabeledExprListSyntax.self)?.first?.expression
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
    ///   * Attached declaration is an enum declaration.
    ///   * This attribute must be combined with `Codable`
    ///   and `CodedAt` attribute.
    ///   * This attribute mustn't be combined with `CodedBy`
    ///     attribute.
    /// * If macro has one argument provided:
    ///   * Attached declaration is an enum-case declaration.
    ///   * This attribute isn't used combined with `IgnoreCoding`
    ///     attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                has(arguments: 1),
                AggregatedDiagnosticProducer {
                    expect(syntaxes: EnumCaseDeclSyntax.self)
                    cantBeCombined(with: IgnoreCoding.self)
                },
                else: AggregatedDiagnosticProducer {
                    expect(syntaxes: EnumDeclSyntax.self)
                    mustBeCombined(with: Codable.self)
                    mustBeCombined(with: CodedAt.self)
                    cantBeCombined(with: CodedBy.self)
                }
            )
        }
    }
}

extension Registration where Key == ExprSyntax?, Decl: AttributableDeclSyntax {
    /// Update registration with alternate value expression data.
    ///
    /// New registration is updated with value expression data that will be
    /// used for decoding/encoding, if provided and registration doesn't
    /// already have a value.
    ///
    /// - Returns: Newly built registration with value expression data.
    func checkForAlternateValue() -> Self {
        guard
            self.key == nil,
            let attr = CodedAs(from: self.decl)
        else { return self }
        return self.updating(with: attr.expr)
    }
}
