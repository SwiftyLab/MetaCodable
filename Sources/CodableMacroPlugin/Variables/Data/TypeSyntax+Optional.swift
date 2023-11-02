@_implementationOnly import SwiftSyntax

/// An extension that handles
/// optional type syntaxes.
extension TypeSyntax {
    /// Check whether current type syntax
    /// represents an optional type.
    ///
    /// Checks whether the type syntax uses
    /// `?` optional type syntax (i.e. `Type?`) or
    /// generic optional syntax (i.e. `Optional<Type>`).
    var isOptional: Bool {
        if self.is(OptionalTypeSyntax.self) {
            return true
        } else if let type = self.as(IdentifierTypeSyntax.self),
            type.name.text == "Optional",
            let gArgs = type.genericArgumentClause?.arguments,
            gArgs.count == 1
        {
            return true
        } else {
            return false
        }
    }

    /// Provides type and method expression to use
    /// with container expression for decoding/encoding.
    ///
    /// For optional types `IfPresent` is added to
    /// the `method` name passed and wrapped
    /// type is passed as type, otherwise `method`
    /// name and type are used as is.
    ///
    /// - Parameter method: The default method name.
    /// - Returns: The type and method expression
    ///   for decoding/encoding.
    func codingTypeMethod(
        forMethod method: TokenSyntax
    ) -> (TypeSyntax, TokenSyntax) {
        let (dType, dMethod): (TypeSyntax, TokenSyntax)
        if let type = self.as(OptionalTypeSyntax.self) {
            dType = type.wrappedType
            dMethod = "\(method)IfPresent"
        } else if let type = self.as(IdentifierTypeSyntax.self),
            type.name.text == "Optional",
            let gArgs = type.genericArgumentClause?.arguments,
            gArgs.count == 1,
            let type = gArgs.first?.argument
        {
            dType = type
            dMethod = "\(method)IfPresent"
        } else {
            dType = self
            dMethod = method
        }
        return (dType, dMethod)
    }
}
