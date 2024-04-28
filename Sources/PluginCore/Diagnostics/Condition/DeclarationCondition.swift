import SwiftSyntax

/// Validates provided syntax is of current declaration.
///
/// Checks provided syntax type is of the syntax type `S`.
struct DeclarationCondition<S: SyntaxProtocol>: DiagnosticCondition {
    /// Determines whether provided syntax passes validation.
    ///
    /// This type checks the provided syntax with current data for validation.
    /// Checks provided syntax type is of the syntax type `S`.
    ///
    /// - Parameter syntax: The syntax to validate.
    /// - Returns: Whether syntax passes validation.
    func satisfied(by syntax: some SyntaxProtocol) -> Bool {
        return syntax.is(S.self)
    }
}

extension Attribute {
    /// Whether declaration is `struct` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isStruct: DeclarationCondition<StructDeclSyntax> { .init() }
    /// Whether declaration is `class` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isClass: DeclarationCondition<ClassDeclSyntax> { .init() }
    /// Whether declaration is `actor` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isActor: DeclarationCondition<ActorDeclSyntax> { .init() }
    /// Whether declaration is `enum` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isEnum: DeclarationCondition<EnumDeclSyntax> { .init() }
    /// Whether declaration is `protocol` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isProtocol: DeclarationCondition<ProtocolDeclSyntax> { .init() }
    /// Whether declaration is `variable` declaration.
    ///
    /// Uses `DeclarationCondition` to check syntax type.
    var isVariable: DeclarationCondition<VariableDeclSyntax> { .init() }
}
