import SwiftSyntax

/// Attribute type for `Inherits` macro-attribute.
///
/// This type can validate`Inherits` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
///
/// Attaching this macro to type allows indicating the generated
/// `Codable` conformance whether a class already inheriting
/// conformance from super class or not.
package struct Inherits: PeerAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// Whether super class conforms to `Decodable`.
    ///
    /// In case of no super class, this should be `false`.
    var decodable: Bool {
        return node.arguments?.as(LabeledExprListSyntax.self)?.first { expr in
            expr.label?.tokenKind == .identifier("decodable")
        }?.expression.as(BooleanLiteralExprSyntax.self)?.literal
            .tokenKind == .keyword(.true)
    }

    /// Whether super class conforms to `Encodable`.
    ///
    /// In case of no super class, this should be `false`.
    var encodable: Bool {
        return node.arguments?.as(LabeledExprListSyntax.self)?.first { expr in
            expr.label?.tokenKind == .identifier("encodable")
        }?.expression.as(BooleanLiteralExprSyntax.self)?.literal
            .tokenKind == .keyword(.true)
    }

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
    /// Builds diagnoser that validates attached declaration
    /// is a class declaration, has `Codable` macro attached
    /// and macro usage is not duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            shouldNotDuplicate()
            mustBeCombined(with: Codable.self)
            expect(syntaxes: ClassDeclSyntax.self)
        }
    }
}
