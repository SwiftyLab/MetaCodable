import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `DecodedAt` macro-attribute.
///
/// This type can validate `DecodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct DecodedAt: PropertyAttribute {
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
    /// * If macro is attached to enum/protocol declaration:
    ///   * This attribute must be combined with `Codable`
    ///     attribute.
    ///   * This attribute isn't used combined with `UnTagged`
    ///     attribute.
    ///   * This attribute isn't used combined with `CodedAt`
    ///     attribute.
    ///   * This attribute must be combined with `EncodedAt`
    ///     attribute.
    /// * else:
    ///   * Attached declaration is a variable declaration.
    ///   * Attached declaration is not a grouped variable
    ///     declaration.
    ///   * Attached declaration is not a static variable
    ///     declaration.
    ///   * This attribute isn't used combined with `CodedIn`
    ///     `CodedAt` and `IgnoreCoding` attribute.
    func diagnoser() -> DiagnosticProducer {
        AggregatedDiagnosticProducer {
            cantDuplicate()
            `if`(
                isEnum || isProtocol,
                AggregatedDiagnosticProducer {
                    mustBeCombined(with: Codable.self)
                    cantBeCombined(with: UnTagged.self)
                    cantBeCombined(with: CodedAt.self)
                    mustBeCombined(with: EncodedAt.self)
                },
                else: AggregatedDiagnosticProducer {
                    attachedToUngroupedVariable()
                    attachedToNonStaticVariable()
                    cantBeCombined(with: CodedIn.self)
                    cantBeCombined(with: CodedAt.self)
                    cantBeCombined(with: IgnoreCoding.self)
                }
            )
        }
    }
}

extension DecodedAt: KeyPathProvider {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// Always `true` for this type.
    var provided: Bool { true }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path overrides current `CodingKey` path data
    /// for decoding, but not for encoding.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String] { providedPath }
}
