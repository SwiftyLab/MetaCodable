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
package struct IgnoreCodingInitialized: PeerAttribute {
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
            shouldNotDuplicate()
            `if`(
                isStruct || isClass || isEnum,
                mustBeCombined(with: Codable.self),
                else: expect(syntaxes: EnumCaseDeclSyntax.self)
            )
        }
    }
}

extension Registration where Var: ValuedVariable {
    /// Update registration whether decoding/encoding to be ignored.
    ///
    /// New registration is updated with decoding and encoding condition
    /// depending on whether already initialized. Already initialized variables
    /// are updated to be ignored in decoding/encoding.
    ///
    /// - Parameter decl: The declaration to check for attribute.
    /// - Returns: Newly built registration with conditional decoding/encoding
    ///   data.
    func checkInitializedCodingIgnored<D: AttributableDeclSyntax>(
        attachedAt decl: D
    ) -> Registration<Decl, Key, ConditionalCodingVariable<Var>> {
        typealias Output = ConditionalCodingVariable<Var>
        let attr = IgnoreCodingInitialized(from: decl)
        let code = attr != nil ? self.variable.value == nil : nil
        let options = Output.Options(
            decode: code, encode: code, encodingConditionExpr: nil
        )
        let newVariable = Output(base: self.variable, options: options)
        return self.updating(with: newVariable)
    }
}
