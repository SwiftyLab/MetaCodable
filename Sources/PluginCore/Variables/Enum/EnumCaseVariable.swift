@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing data associated with an enum-case declarations.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
protocol EnumCaseVariable: ConditionalVariable, NamedVariable
where CodingLocation == EnumCaseCodingLocation, Generated == SwitchCaseSyntax {
    /// All the associated variables for this case.
    ///
    /// Represents all the associated variable data available in this
    /// enum-case declaration data.
    var variables: [any AssociatedVariable] { get }
}

/// Represents the location for decoding/encoding for `EnumCaseVariable`s.
///
/// Represents the container and value for `EnumCaseVariable`s
/// decoding/encoding.
struct EnumCaseCodingLocation {
    /// The decoder/encoder for decoding
    /// or encoding enum-case content.
    ///
    /// This decoder/encoder is used for decoding
    /// or encoding enum-case associated variables.
    let coder: TokenSyntax
    /// The callback to generate case variation data.
    ///
    /// Each enum-case passes its value to this callback
    /// to generate case variation decoding/encoding syntax.
    let action: EnumSwitcherGenerated.CoderCallback
    /// The values of the variable.
    ///
    /// Represents the actual values that will be decoded.
    /// Only the first value will be encoded.
    let values: [ExprSyntax]
    /// The enum-case decoding/encoding expression generation
    /// callback.
    ///
    /// The enum-case passes case name and associated variables
    /// to this callback to generate decoding/encoding expression.
    let expr: EnumVariable.CaseCode
}
