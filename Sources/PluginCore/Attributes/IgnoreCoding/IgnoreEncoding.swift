import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `IgnoreEncoding` macro-attribute.
///
/// This type can validate`IgnoreEncoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct IgnoreEncoding: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// Optional encoding condition closure specified.
    ///
    /// This closure may take one or multiple arguments depending on
    /// whether attached to property or enum case.
    ///
    /// The return type of closure in `Bool`, based on this value encoding
    /// is decided to be performed or ignored.
    var conditionExpr: ExprSyntax? {
        return node.arguments?.as(LabeledExprListSyntax.self)?.first { expr in
            expr.label?.tokenKind == .identifier("if")
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

    /// Builds diagnoser that can validate this macro attached declaration.
    ///
    /// The following conditions are checked by the built diagnoser:
    /// * Attached declaration is a variable/type/enum-case declaration.
    /// * Additionally, warning generated if macro usage is duplicated
    ///   for the same declaration.
    /// * Additionally, warning also generated if this attribute is used
    ///   combined with `IgnoreCoding` attribute.
    /// * Attached type declaration must not have`Codable` attribute
    ///   attached.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            shouldNotBeCombined(with: IgnoreCoding.self)
            `if`(
                isStruct || isClass || isActor || isEnum || isProtocol,
                mustBeCombined(with: Codable.self),
                else: expect(syntaxes: IgnoreCoding.ignorableDeclarations)
            )
        }
    }
}
