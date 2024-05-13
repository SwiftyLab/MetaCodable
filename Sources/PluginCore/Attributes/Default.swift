import SwiftSyntax

/// Attribute type for `Default` macro-attribute.
///
/// This type can validate`Default` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct Default: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The default value expression provided for value missing case.
    ///
    /// This expression should be used only when value is missing
    /// in the decoding syntax.
    var onMissingExpr: ExprSyntax {
        return node.arguments?.as(LabeledExprListSyntax.self)?.first { expr in
            expr.label?.tokenKind == .identifier("ifMissing")
        }?.expression
            ?? node.arguments!
            .as(LabeledExprListSyntax.self)!.first!.expression
    }

    /// The default value expression provided for errors.
    ///
    /// This expression should be used for errors other than
    /// value is missing in the decoding syntax.
    var onErrorExpr: ExprSyntax? {
        guard
            let exprs = node.arguments?.as(LabeledExprListSyntax.self),
            !exprs.isEmpty
        else { return nil }
        guard
            exprs.count > 1 || exprs.first?.label != nil
        else { return exprs.first!.expression }
        return node.arguments?.as(LabeledExprListSyntax.self)?.first { expr in
            expr.label?.tokenKind == .identifier("forErrors")
        }?.expression
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
    /// * Attached declaration is a variable declaration.
    /// * Attached declaration is not a static variable
    ///   declaration
    /// * Macro usage is not duplicated for the same
    ///   declaration.
    /// * This attribute isn't used combined with
    ///   `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(syntaxes: VariableDeclSyntax.self)
            attachedToNonStaticVariable()
            cantDuplicate()
            cantBeCombined(with: IgnoreCoding.self)
        }
    }
}

extension Registration
where
    Decl: AttributableDeclSyntax, Var: PropertyVariable,
    Var.Initialization == RequiredInitialization
{
    /// The variable data with default expression
    /// that output registration will have.
    typealias DefOutput = AnyPropertyVariable<AnyRequiredVariableInitialization>
    /// Update registration with default value if exists.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Returns: Newly built registration with default expression data.
    func addDefaultValueIfExists() -> Registration<Decl, Key, DefOutput> {
        guard let attr = Default(from: self.decl)
        else { return self.updating(with: self.variable.any) }
        let newVar = self.variable.with(
            onMissingExpr: attr.onMissingExpr, onErrorExpr: attr.onErrorExpr
        )
        return self.updating(with: newVar.any)
    }
}

fileprivate extension PropertyVariable
where Initialization == RequiredInitialization {
    /// Update variable data with the default value expression provided.
    ///
    /// `DefaultValueVariable` is created with this variable as base
    /// and default expression provided.
    ///
    /// - Parameters:
    ///   - mExpr: The missing value default expression to add.
    ///   - eExpr: The other errors default expression to add.
    ///
    /// - Returns: Created variable data with default expression.
    func with(
        onMissingExpr mExpr: ExprSyntax, onErrorExpr eExpr: ExprSyntax?
    ) -> DefaultValueVariable<Self> {
        return .init(
            base: self, options: .init(onMissingExpr: mExpr, onErrorExpr: eExpr)
        )
    }
}
