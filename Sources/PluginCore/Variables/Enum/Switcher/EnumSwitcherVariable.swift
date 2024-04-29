import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with an enum variable switch case.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
protocol EnumSwitcherVariable: Variable
where
    CodingLocation == EnumSwitcherLocation, Generated == CodeBlockItemListSyntax
{
    /// Provides node at which case associated variables are registered.
    ///
    /// The returned node can be used by enum-case variables to register
    /// their associated variables for which decoding and encoding syntax
    /// can be generated.
    ///
    /// - Parameters:
    ///   - decl: The declaration for which to provide.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The registering node.
    func node(
        for decl: EnumCaseVariableDeclSyntax,
        in context: some MacroExpansionContext
    ) -> PropertyVariableTreeNode

    /// Creates value expressions for provided enum-case variable.
    ///
    /// Determines the value of enum-case variable to have `CodingKey`
    /// based values or any raw values.
    ///
    /// - Parameters:
    ///   - variable: The variable for which generated.
    ///   - values: The values present in syntax.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated value.
    func keyExpression<Var: EnumCaseVariable>(
        for variable: Var, values: [ExprSyntax],
        codingKeys: CodingKeysMap, context: some MacroExpansionContext
    ) -> EnumVariable.CaseValue

    /// Update provided variable data.
    ///
    /// An `EnumSwitcherVariable` can update the data of provided variable
    /// before variable is processed for additional macro data inputs.
    ///
    /// - Parameter variable: The variable to transform.
    /// - Returns: Transformed variable.
    func transform(variable: BasicAssociatedVariable) -> BasicAssociatedVariable

    /// Creates additional enum declarations for enum variable.
    ///
    /// The generated enum is a raw enum of `String` type
    /// and confirms to `CodingKey`.
    ///
    /// - Parameter context: The macro expansion context.
    /// - Returns: The generated enum declaration syntax.
    func codingKeys(
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax
}

extension EnumSwitcherVariable {
    /// Update provided variable data.
    ///
    /// Provided variable is returned as it is, without any data update.
    ///
    /// - Parameter variable: The variable to transform.
    /// - Returns: Transformed variable.
    func transform(
        variable: BasicAssociatedVariable
    ) -> BasicAssociatedVariable {
        return variable
    }
}

/// Represents the location for decoding/encoding for `EnumSwitcherVariable`.
///
/// These data will be used to generated switch expression syntax and
/// additional code.
package struct EnumSwitcherLocation {
    ///The decoder/encoder syntax to use.
    ///
    /// Represents the decoder/encoder argument syntax for
    /// the `Codable` conformance implementation methods.
    let coder: TokenSyntax
    ///The decoding/encoding container syntax to use.
    ///
    /// Represents the primary container created from decoder/encoder.
    let container: TokenSyntax
    /// The `CodingKey` type.
    ///
    /// Represents the `CodingKeys` type
    /// expression containing all keys.
    let keyType: ExprSyntax
    /// The current enum type.
    ///
    /// Represents the type expression of enum
    /// for which declaration being generated.
    let selfType: ExprSyntax
    /// The current enum value.
    ///
    /// Represents the value expression present
    /// in switch header and compared.
    let selfValue: ExprSyntax
    /// All the cases of the enum.
    ///
    /// Represents all enum cases and their decoding/encoding values.
    let cases: [EnumVariable.Case]
    /// The enum-case decoding/encoding expression generation
    /// callback.
    ///
    /// The enum-case passes case name and associated variables
    /// to this callback to generate decoding/encoding expression.
    let codeExpr: EnumVariable.CaseCode
    /// Whether the generated switch expression should have default case.
    ///
    /// Based on type of tagging in enums the default case generation for
    /// both decoding and encoding can be customized.
    let hasDefaultCase: Bool
}
