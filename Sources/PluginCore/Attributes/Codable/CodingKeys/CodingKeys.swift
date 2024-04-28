import SwiftSyntax

/// Attribute type for `CodingKeys` macro-attribute.
///
/// This type can validate`CodingKeys` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
///
/// Attaching this macro to type declaration indicates all the
/// property names will be converted to `CodingKey` value
/// using the strategy provided.
package struct CodingKeys: PeerAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The key transformation strategy provided.
    var strategy: Strategy {
        let expr = node.arguments!
            .as(LabeledExprListSyntax.self)!.first!.expression
        return .init(with: expr)
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
    /// has `Codable` macro attached and macro usage
    /// is not duplicated for the same declaration.
    ///
    /// For enum case declarations this attribute can be attached
    /// without `Codable` macro.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isStruct || isClass || isEnum,
                mustBeCombined(with: Codable.self),
                else: expect(syntaxes: EnumCaseDeclSyntax.self)
            )
        }
    }
}

extension Registration where Key == [String] {
    /// Update current registration `CodingKey` path data.
    ///
    /// New registration is updated with the transformed `CodingKey` path
    /// based on provided `strategy`.
    ///
    /// - Parameter decl: The declaration where `strategy` provided.
    /// - Returns: Newly built registration with transformed `CodingKey` path data.
    func transformKeysAccordingToStrategy<D>(
        attachedTo decl: D
    ) -> Self where D: AttributableDeclSyntax {
        guard let attr = CodingKeys(from: decl) else { return self }
        let strategy = attr.strategy
        return self.updating(with: strategy.transform(keyPath: self.key))
    }
}
