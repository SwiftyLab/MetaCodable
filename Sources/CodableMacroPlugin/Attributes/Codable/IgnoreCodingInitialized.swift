import SwiftSyntax

/// Attribute type for `IgnoreCodingInitialized` macro-attribute.
///
/// This type can validate`IgnoreCodingInitialized` macro-attribute
/// usage and extract data for `Codable` macro to generate implementation.
///
/// Attaching this macro to type declaration indicates all the initialized
/// properties for the said type will be ignored from decoding and
/// encoding unless explicitly asked with attached coding attributes,
/// i.e. `CodedIn`, `CodedAt` etc.
struct IgnoreCodingInitialized: PeerAttribute {
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
    /// Builds diagnoser that validates attached declaration
    /// has `Codable` macro attached and macro usage
    /// is not duplicated for the same declaration.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> any DiagnosticProducer {
        AggregatedDiagnosticProducer {
            mustBeCombined(with: Codable.self)
            shouldNotDuplicate()
        }
    }
}
