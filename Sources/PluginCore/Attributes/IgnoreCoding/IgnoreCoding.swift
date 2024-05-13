import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `IgnoreCoding` macro-attribute.
///
/// This type can validate`IgnoreCoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct IgnoreCoding: PropertyAttribute {
    /// Declarations that can have decoding/encoding ignore.
    ///
    /// Represents declarations that can have `IgnoreCoding`,
    /// `IgnoreDecoding`, `IgnoreEncoding` macros attached.
    static let ignorableDeclarations: [SyntaxProtocol.Type] = [
        VariableDeclSyntax.self,
        EnumCaseDeclSyntax.self,
        StructDeclSyntax.self,
        ClassDeclSyntax.self,
        EnumDeclSyntax.self,
        ActorDeclSyntax.self,
    ]

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
    /// The following conditions are checked by the built diagnoser:
    /// * Attached declaration is a variable/type/enum-case declaration.
    /// * Attached variable declaration has default initialization or
    ///   variable is a computed property.
    /// * This attribute isn't used combined with `CodedIn`, `CodedAt`,
    ///   `CodedAs`, `CodedBy` and `ContentAt` attribute.
    /// * Additionally, warning generated if macro usage is duplicated
    ///   for the same declaration.
    /// * Attached type declaration must not have`Codable` attribute
    ///   attached.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            cantBeCombined(with: CodedIn.self)
            cantBeCombined(with: CodedAt.self)
            cantBeCombined(with: CodedAs.self)
            cantBeCombined(with: CodedBy.self)
            cantBeCombined(with: ContentAt.self)
            shouldNotDuplicate()
            `if`(
                isVariable, attachedToInitializedVariable(),
                else: `if`(
                    isStruct || isClass || isActor || isEnum || isProtocol,
                    cantBeCombined(with: Codable.self),
                    else: expect(syntaxes: Self.ignorableDeclarations)
                )
            )
        }
    }
}

extension Registration
where
    Decl: AttributableDeclSyntax, Var: ConditionalVariable,
    Var.Generated: ConditionalVariableSyntax
{
    /// The output registration variable type that handles conditional
    /// decoding/encoding data.
    typealias ConditionalOutput = ConditionalCodingVariable<Var>
    /// Update registration whether decoding/encoding to be ignored.
    ///
    /// New registration is updated with conditional decoding/encoding data
    /// indicating whether variable needs to decoded/encoded.
    ///
    /// Checks the following criteria to decide decoding/encoding condition
    /// for variable:
    /// * Ignores for decoding, if `@IgnoreCoding` or `@IgnoreDecoding`
    ///   macro attached.
    /// * Ignores for encoding, if `@IgnoreCoding` or `@IgnoreEncoding`
    ///   macro attached.
    ///
    /// - Returns: Newly built registration with conditional decoding/encoding
    ///   data.
    func checkCodingIgnored() -> Registration<Decl, Key, ConditionalOutput> {
        typealias Output = ConditionalOutput
        let ignoreCoding = IgnoreCoding(from: self.decl) != nil
        let ignoreDecoding = IgnoreDecoding(from: self.decl) != nil
        let ignoreEncodingAttr = IgnoreEncoding(from: self.decl)
        let conditionExpr = ignoreEncodingAttr?.conditionExpr
        let ignoreEncoding = ignoreEncodingAttr != nil && conditionExpr == nil
        let decode = !ignoreCoding && !ignoreDecoding
        let encode = !ignoreCoding && !ignoreEncoding
        let options = Output.Options(
            decode: decode, encode: encode, encodingConditionExpr: conditionExpr
        )
        let newVariable = Output(base: self.variable, options: options)
        return self.updating(with: newVariable)
    }
}

/// An attribute type indicating explicit decoding/encoding when attached
/// to variable declarations.
///
/// Attaching attributes of this type to computed properties indicates
/// this variable should be encoded for the type.
fileprivate protocol CodingAttribute: PropertyAttribute {}
extension CodedIn: CodingAttribute {}
extension CodedAt: CodingAttribute {}
extension CodedBy: CodingAttribute {}
extension Default: CodingAttribute {}
