@_implementationOnly import SwiftDiagnostics
@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// Attribute type for `CodedAt` macro-attribute.
///
/// This type can validate`CodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAt: PropertyAttribute {
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
    /// * Macro usage is not duplicated for the same declaration.
    /// * If macro is attached to enum declaration:
    ///   * This attribute must be combined with `Codable`
    ///   and `TaggedAt` attribute.
    /// * else:
    ///   * Attached declaration is a variable declaration.
    ///   * Attached declaration is not a grouped variable
    ///     declaration.
    ///   * Attached declaration is not a static variable
    ///     declaration
    ///   * This attribute isn't used combined with `CodedIn`
    ///     and `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isEnum,
                AggregatedDiagnosticProducer {
                    mustBeCombined(with: Codable.self)
                    mustBeCombined(with: TaggedAt.self)
                },
                else: AggregatedDiagnosticProducer {
                    attachedToUngroupedVariable()
                    attachedToNonStaticVariable()
                    cantBeCombined(with: CodedIn.self)
                    cantBeCombined(with: IgnoreCoding.self)
                }
            )
        }
    }
}
