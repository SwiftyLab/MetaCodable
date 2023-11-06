@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxBuilder
@_implementationOnly import SwiftSyntaxMacros

/// A variable value containing default expression for decoding failure.
///
/// The `DefaultValueVariable` customizes decoding and initialization
/// by using the default expression provided during initialization:
/// * For initializing variable in case of decoding failure.
/// * For providing default value to variable in memberwise initializer(s).
struct DefaultValueVariable<Var: Variable>: ComposedVariable
where Var.Initialization == RequiredInitialization {
    /// The customization options for `DefaultValueVariable`.
    ///
    /// `DefaultValueVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
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
    let base: Var
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Whether the variable is to
    /// be decoded.
    ///
    /// Always `true` for this type.
    var decode: Bool? { true }
    /// Whether the variable is to
    /// be encoded.
    ///
    /// Always `true` for this type.
    var encode: Bool? { true }

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Decodable` conformance.
    var requireDecodable: Bool? { base.requireDecodable }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Encodable` conformance.
    var requireEncodable: Bool? { base.requireEncodable }

    /// Indicates the initialization type for this variable.
    ///
    /// Provides default initialization value in initialization
    /// function parameter.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: MacroExpansionContext
    ) -> RequiredInitializationWithDefaultValue {
        let initialization = base.initializing(in: context)
        return .init(base: initialization, expr: options.expr)
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
        in context: MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        let catchClauses = CatchClauseListSyntax {
            CatchClauseSyntax { "self.\(name) = \(options.expr)" }
        }
        var doClauses = base.decoding(in: context, from: location)
        if type.isOptional, !doClauses.isEmpty {
            let lastIndex = doClauses.index(before: doClauses.endIndex)
            let assignmentblock = doClauses.remove(at: lastIndex)
            doClauses.append("\(assignmentblock) ?? \(options.expr)")
        }
        return CodeBlockItemListSyntax {
            DoStmtSyntax(catchClauses: catchClauses) { doClauses }
        }
    }
}
