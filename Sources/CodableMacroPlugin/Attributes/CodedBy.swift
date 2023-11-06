@_implementationOnly import SwiftSyntax

/// Attribute type for `CodedBy` macro-attribute.
///
/// This type can validate`CodedBy` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedBy: PropertyAttribute {
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
                .description == Self.name
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
            expect(syntax: VariableDeclSyntax.self)
            attachedToNonStaticVariable()
            cantDuplicate()
            cantBeCombined(with: IgnoreCoding.self)
        }
    }
}
