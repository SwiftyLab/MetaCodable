import SwiftSyntax

/// A `VariableSyntax` type representing enum-case associated variables.
///
/// Represents an individual associated variables declaration in an enum-case.
struct AssociatedDeclSyntax: VariableSyntax, AttributableDeclSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// Represents basic associated variable decoding/encoding data.
    typealias Variable = BasicAssociatedVariable

    /// The name of variable.
    ///
    /// Created from the second name if exists, first name if exists
    /// falling back to position of variable respectively.
    let name: TokenSyntax
    /// The `CodingKey` path of variable.
    ///
    /// The path is empty if no first or second name exists.
    /// Otherwise second or first name used respectively.
    let path: [String]
    /// The actual variable syntax.
    ///
    /// Defines the actual associated values declaration.
    let param: EnumCaseParameterSyntax
    /// The parent declaration.
    ///
    /// Represents the enum-case variable declaration.
    let parent: EnumCaseVariableDeclSyntax

    /// The attributes attached to variable.
    ///
    /// The attributes attached to associated variable declaration.
    var attributes: AttributeListSyntax {
        // TODO: Revisit once attributes support added to associated variables.
        //https://forums.swift.org/t/attached-macro-support-for-enum-case-arguments/67952
        return []
    }
}
