import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `IgnoreCoding` macro-attribute.
///
/// This type can validate`IgnoreCoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct IgnoreCoding: PropertyAttribute {
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
    /// * Attached variable declaration has default
    ///   initialization or variable is a computed property.
    /// * This attribute isn't used combined with `CodedIn`
    ///   and `CodedAt` attribute.
    /// * Additionally, warning generated if macro usage
    ///   is duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> any DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            attachedToInitializedVariable()
            cantBeCombined(with: CodedIn.self)
            cantBeCombined(with: CodedAt.self)
            shouldNotDuplicate()
        }
    }
}
