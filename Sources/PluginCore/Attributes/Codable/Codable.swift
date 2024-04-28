import SwiftSyntax

/// Attribute type for `Codable` macro-attribute.
///
/// Describes a macro that validates `Codable` macro usage
/// and generates `Codable` conformances and implementations.
///
/// This macro performs extension macro expansion depending on `Codable`
/// conformance of type:
///   * Extension macro expansion, to confirm to `Decodable` or `Encodable`
///     protocols depending on whether type doesn't already conform to `Decodable`
///     or `Encodable` respectively.
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Codable` implementation of both `init(from:)` and `encode(to:)`
///     methods.
///   * If attached declaration already conforms to `Codable` this macro expansion
///     is skipped.
package struct Codable: Attribute {
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
    /// Builds diagnoser that validates attached declaration
    /// is `struct`/`class`/`enum`/`protocol` declaration
    /// and macro usage is not duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(
                syntaxes: StructDeclSyntax.self, ClassDeclSyntax.self,
                EnumDeclSyntax.self, ActorDeclSyntax.self,
                ProtocolDeclSyntax.self
            )
            cantDuplicate()
        }
    }
}
