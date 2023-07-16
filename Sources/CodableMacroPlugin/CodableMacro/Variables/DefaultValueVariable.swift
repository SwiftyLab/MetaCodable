import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// A variable value containing default expression for decoding failure.
///
/// The `DefaultValueVariable` customizes decoding and initialization
/// by using the default expression provided during initialization:
/// * For initializing variable in case of decoding failure.
/// * For providing default value to variable in member-wise initializer.
struct DefaultValueVariable<V: Variable>: Variable {
    /// The customization option for `DefaultValueVariable`.
    ///
    /// `DefaultValueVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Option {
        /// The default expression used when decoding fails.
        ///
        /// This expression is provided during initialization
        /// and used to generate non-failable decoding syntax
        /// by using this when decoding fails.
        let expr: ExprSyntax
    }

    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: V
    /// The option for customizations.
    ///
    /// Option is provided during initialization.
    let option: Option

    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var type: TypeSyntax { base.type }

    /// Indicates the initialization type for this variable.
    ///
    /// Provides default initialization value in initialization
    /// function parameter.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> VariableInitialization {
        return .required(
            "\(name): \(type) = \(option.expr)",
            "self.\(name) = \(name)"
        )
    }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Wraps code syntax for decoding of the underlying
    /// variable value in `do` block and initializes with
    /// default expression in the `catch` block.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        let catchClauses = CatchClauseListSyntax {
            CatchClauseSyntax { "self.\(name) = \(option.expr)" }
        }
        return CodeBlockItemListSyntax {
            DoStmtSyntax(catchClauses: catchClauses) {
                base.decoding(in: context, from: location)
            }
        }
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for encoding of the underlying
    /// variable value.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        return base.encoding(in: context, to: location)
    }
}
