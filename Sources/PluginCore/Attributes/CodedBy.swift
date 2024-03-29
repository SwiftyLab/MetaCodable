@_implementationOnly import SwiftSyntax

/// Attribute type for `CodedBy` macro-attribute.
///
/// This type can validate`CodedBy` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct CodedBy: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The helper coding instance
    /// expression provided.
    var expr: ExprSyntax {
        return node.arguments!
            .as(LabeledExprListSyntax.self)!.first!.expression
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
    /// * If attached declaration is enum/protocol declaration:
    ///   * This attribute must be combined with `Codable`
    ///     and `CodedAt` attribute.
    ///   * This attribute mustn't be combined with `CodedAs`
    ///     attribute.
    /// * If macro has one argument provided:
    ///   * Attached declaration is a variable declaration.
    ///   * Attached declaration is not a static variable
    ///     declaration
    ///   * This attribute isn't used combined with
    ///     `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isEnum || isProtocol,
                AggregatedDiagnosticProducer {
                    mustBeCombined(with: Codable.self)
                    mustBeCombined(with: CodedAt.self)
                    cantBeCombined(with: CodedAs.self)
                },
                else: AggregatedDiagnosticProducer {
                    expect(syntaxes: VariableDeclSyntax.self)
                    attachedToNonStaticVariable()
                    cantBeCombined(with: IgnoreCoding.self)
                }
            )
        }
    }
}

extension Registration
where
    Decl: AttributableDeclSyntax, Var: DefaultPropertyVariable,
    Var.Initialization: RequiredVariableInitialization
{
    /// The optional variable data with helper expression
    /// that output registration will have.
    typealias CodedByOutput = AnyPropertyVariable<Var.Initialization>
    /// Update registration with helper expression data.
    ///
    /// New registration is updated with helper expression data that will be
    /// used for decoding/encoding, if provided.
    ///
    /// - Returns: Newly built registration with helper expression data.
    func useHelperCoderIfExists() -> Registration<Decl, Key, CodedByOutput> {
        guard let attr = CodedBy(from: self.decl)
        else { return self.updating(with: self.variable.any) }
        let newVar = self.variable.with(helper: attr.expr)
        return self.updating(with: newVar.any)
    }
}

fileprivate extension DefaultPropertyVariable {
    /// Update variable data with the helper instance expression provided.
    ///
    /// `HelperCodedVariable` is created with this variable as base
    /// and helper expression provided.
    ///
    /// - Parameter expr: The helper expression to add.
    /// - Returns: Created variable data with helper expression.
    func with(helper expr: ExprSyntax) -> HelperCodedVariable<Self> {
        return .init(base: self, options: .init(expr: expr))
    }
}
