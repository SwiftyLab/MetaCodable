import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with a property variable
/// inside types/enum-case declarations.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
package protocol PropertyVariable<Initialization>: NamedVariable,
    ValuedVariable, ConditionalVariable, InitializableVariable
where
    CodingLocation == PropertyCodingLocation,
    Generated == CodeBlockItemListSyntax, Initialization: VariableInitialization
{
    /// The type of the variable.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   let variable: String = "data"
    ///   ```
    ///   the `type` will be `String`.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   (_ variable: String = "data")
    ///   ```
    ///   the `type` will be `String`.
    var type: TypeSyntax { get }

    /// Whether the variable type requires
    /// `Decodable` conformance.
    ///
    /// Used for generic where clause, for
    /// `Decodable` conformance generation.
    ///
    /// If `nil` is returned, variable is used in
    /// generic where clause by default.
    var requireDecodable: Bool? { get }
    /// Whether the variable type requires
    /// `Encodable` conformance.
    ///
    /// Used for generic where clause, for
    /// `Encodable` conformance generation.
    ///
    /// If `nil` is returned, variable is used in
    /// generic where clause by default.
    var requireEncodable: Bool? { get }

    /// The prefix token to use along with `name` when decoding.
    ///
    /// When generating decode implementation the prefix
    /// is used before `name` during assignment.
    var decodePrefix: TokenSyntax { get }
    /// The prefix token to use along with `name` when encoding.
    ///
    /// When generating encode implementation the prefix
    /// is used before `name` during method invocation.
    var encodePrefix: TokenSyntax { get }

    /// The fallback behavior when decoding fails.
    ///
    /// In the event this decoding this variable is failed,
    /// appropriate fallback would be applied.
    var decodingFallback: DecodingFallback { get }
}

/// Represents the location for decoding/encoding for `Variable`s.
///
/// Represents whether `Variable`s need to decode/encode directly
/// from/to the decoder/encoder respectively or at path of a container.
package enum PropertyCodingLocation {
    /// Represents a top-level decoding/encoding location.
    ///
    /// The variable needs to be decoded/encoded directly to the
    /// decoder/encoder provided, not nested at a `CodingKey`.
    ///
    /// - Parameters:
    ///   - coder: The decoder/encoder for decoding/encoding.
    ///   - method: The method to use for decoding/encoding.
    case coder(_ coder: TokenSyntax, method: ExprSyntax?)
    /// Represents decoding/encoding location at a `CodingKey`
    /// for a container.
    ///
    /// The variable needs to be decoded/encoded at the
    /// `CodingKey` inside the container provided.
    ///
    /// - Parameters:
    ///   - container: The container for decoding/encoding.
    ///   - key: The `CodingKey` inside the container.
    ///   - method: The method to use for decoding/encoding.
    case container(
        _ container: TokenSyntax, key: ExprSyntax,
        method: ExprSyntax?
    )
}

extension PropertyVariable
where Self: ComposedVariable, Self.Wrapped: ConditionalVariable {
    /// The arguments passed to encoding condition.
    ///
    /// Provides arguments of underlying variable value.
    var conditionArguments: LabeledExprListSyntax {
        return base.conditionArguments
    }
}

extension PropertyVariable {
    /// The arguments passed to encoding condition.
    ///
    /// Passes current variable as single argument.
    var conditionArguments: LabeledExprListSyntax {
        return [
            .init(expression: "\(self.encodePrefix)\(self.name)" as ExprSyntax)
        ]
    }

    /// Check whether current type syntax
    /// represents an optional type.
    ///
    /// Checks whether the type syntax uses
    /// `?` optional type syntax (i.e. `Type?`) or
    /// `!` implicitly unwrapped optional type syntax (i.e. `Type!`) or
    /// generic optional syntax (i.e. `Optional<Type>`).
    var hasOptionalType: Bool {
        if type.is(OptionalTypeSyntax.self) {
            return true
        } else if type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return true
        }  else if let type = type.as(IdentifierTypeSyntax.self),
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
        forMethod method: ExprSyntax
    ) -> (TypeSyntax, ExprSyntax) {
        let (dType, dMethod): (TypeSyntax, ExprSyntax)
        if let type = type.as(OptionalTypeSyntax.self) {
            dType = type.wrappedType
            dMethod = "\(method)IfPresent"
        } else if let type = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            dType = type.wrappedType
            dMethod = "\(method)IfPresent"
        } else if let type = type.as(IdentifierTypeSyntax.self),
            type.name.text == "Optional",
            let gArgs = type.genericArgumentClause?.arguments,
            gArgs.count == 1,
            let type = gArgs.first?.argument
        {
            dType = type
            dMethod = "\(method)IfPresent"
        } else {
            dType = type
            dMethod = method
        }
        return (dType, dMethod)
    }
}

extension CodeBlockItemListSyntax: ConditionalVariableSyntax {
    /// Generates new syntax with provided condition.
    ///
    /// Wraps existing syntax with an if expression based on provided condition.
    ///
    /// - Parameter condition: The condition for the existing syntax.
    /// - Returns: The new syntax.
    func adding(condition: LabeledExprListSyntax) -> CodeBlockItemListSyntax {
        let condition = ConditionElementListSyntax {
            .init(condition: .expression("(\(condition))"))
        }
        return CodeBlockItemListSyntax {
            IfExprSyntax(conditions: condition) {
                self
            }
        }
    }
}
