import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `ContentAt` macro-attribute.
///
/// This type can validate`ContentAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct ContentAt: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

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
    /// * Attached declaration is an enum/protocol declaration.
    /// * Macro should be used in presence of `Codable`.
    /// * Macro usage is not duplicated for the same
    ///   declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(syntaxes: EnumDeclSyntax.self, ProtocolDeclSyntax.self)
            mustBeCombined(with: Codable.self)
            mustBeCombined(with: CodedAt.self)
            cantDuplicate()
        }
    }
}

extension ContentAt: KeyPathProvider {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// Always `true` for this type.
    var provided: Bool { true }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path overrides current `CodingKey` path data.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String] { providedPath }
}
