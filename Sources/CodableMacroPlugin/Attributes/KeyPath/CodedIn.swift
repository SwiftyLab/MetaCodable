import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type for `CodedIn` macro-attribute.
///
/// This type can validate`CodedIn` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedIn: PropertyAttribute {
    /// Represents whether initialized
    /// without attribute syntax.
    let inDefaultMode: Bool
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
            node.attributeName.as(SimpleTypeIdentifierSyntax.self)!
                .description == Self.name
        else { return nil }
        self.node = node
        self.inDefaultMode = false
    }

    /// Creates a new instance with default node.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init() {
        self.node = .init("\(raw: Self.name)")
        self.inDefaultMode = true
    }

    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// The following conditions are checked by the
    /// built diagnoser:
    /// * Attached declaration is a variable declaration.
    /// * Macro usage is not duplicated for the same
    ///   declaration.
    /// * This attribute isn't used combined with `CodedAt`
    ///   and `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            expect(syntax: VariableDeclSyntax.self)
            cantDuplicate()
            cantBeCombined(with: CodedAt.self)
            cantBeCombined(with: IgnoreCoding.self)
        }
    }
}
