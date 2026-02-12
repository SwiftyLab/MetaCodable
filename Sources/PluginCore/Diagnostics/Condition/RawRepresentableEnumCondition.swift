import SwiftSyntax

/// Validates provided syntax is a raw representable enum.
///
/// Checks if the provided enum declaration has:
/// 1. An inheritance clause with a raw value type (String, Int, etc.)
/// 2. All enum cases have no associated values (parameter clauses)
struct RawRepresentableEnumCondition: DiagnosticCondition {
    /// Determines whether provided syntax passes validation.
    ///
    /// This type checks the provided syntax with current data for validation.
    /// Checks if the syntax is an enum declaration that conforms to RawRepresentable
    /// by having a raw value type and no associated values in its cases.
    ///
    /// - Parameter syntax: The syntax to validate.
    /// - Returns: Whether syntax passes validation.
    func satisfied(by syntax: some SyntaxProtocol) -> Bool {
        guard let enumDecl = syntax.as(EnumDeclSyntax.self) else {
            return false
        }

        // Check if enum has inheritance clause with raw value type
        let hasRawValueType =
            enumDecl.inheritanceClause?
            .inheritedTypes.contains { $0.type.isRawValueType } ?? false

        // Check if all enum cases have no associated values
        let allCasesHaveNoAssociatedValues = enumDecl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .allSatisfy { caseDecl in
                caseDecl.elements.allSatisfy { element in
                    element.parameterClause == nil
                }
            }

        return hasRawValueType && allCasesHaveNoAssociatedValues
    }
}

extension Attribute {
    /// Whether declaration is a raw representable enum.
    ///
    /// Uses `RawRepresentableEnumCondition` to check if the enum has a raw value type
    /// and no associated values in its cases.
    var isRawRepresentableEnum: RawRepresentableEnumCondition { .init() }
}
