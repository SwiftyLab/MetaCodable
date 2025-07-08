import SwiftSyntax

/// Attribute type for `ConformDecodable` macro-attribute.
///
/// Describes a macro that validates `ConformDecodable` macro usage
/// and generates `Decodable` conformance and implementation.
///
/// This macro performs extension macro expansion to confirm to `Decodable`
/// protocol if the type doesn't already conform to `Decodable`:
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Decodable` implementation of `init(from:)` method.
///   * If attached declaration already conforms to `Decodable` this macro expansion
///     is skipped.
package struct ConformDecodable: PeerAttribute {
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
    package init?(from node: AttributeSyntax) {
        guard
            node.attributeName.as(IdentifierTypeSyntax.self)!
                .name.text == Self.name
        else { return nil }
        self.node = node
    }

    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// Builds diagnoser that validates:
    /// * Attached declaration is `struct`/`class`/`enum`/`protocol` declaration
    /// * This attribute mustn't be combined with `Codable` attribute.
    /// * Macro usage is not duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        AggregatedDiagnosticProducer {
            expect(
                syntaxes: StructDeclSyntax.self, ClassDeclSyntax.self,
                EnumDeclSyntax.self, ActorDeclSyntax.self,
                ProtocolDeclSyntax.self
            )
            cantBeCombined(with: Codable.self)
            cantBeCombined(with: ConformEncodable.self)
            cantDuplicate()
        }
    }
}
