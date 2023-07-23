import SwiftSyntax

/// Attribute type for `Codable` macro-attribute.
///
/// Describes a macro that validates `Codable` macro usage
/// and generates `Codable` conformances and implementations.
///
/// This macro performs two different kinds of expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type
///     for the attached struct declaration named `CodingKeys` and use
///     this type for `Codable` implementation of both `init(from:)`
///     and `encode(to:)` methods by using `CodedPropertyMacro`
///     declarations. Additionally member-wise initializer(s) also generated.
struct Codable: Attribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax
    /// The options for customizations.
    ///
    /// Options is created during
    /// initialization by reading
    /// argument data from
    /// macro-attribute syntax.
    let options: Options

    /// Creates a new instance with the provided node
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax) {
        guard
            node.attributeName.as(SimpleTypeIdentifierSyntax.self)!
                .description == Self.name
        else { return nil }
        self.node = node
        self.options = .init(from: node)
    }

    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// Builds diagnoser that validates attached declaration
    /// is `struct` declaration and macro usage is not
    /// duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(syntax: StructDeclSyntax.self)
            cantDuplicate()
        }
    }
}
