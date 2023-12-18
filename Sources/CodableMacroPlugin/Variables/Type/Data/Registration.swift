@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing variable registration for code generation.
///
/// This type contains variable and `CodingKey` path data
/// that is necessary for syntax generation.
struct Registration<Decl, Var> where Decl: VariableSyntax, Var: Variable {
    /// The `CodingKey` path for the variable.
    ///
    /// The `CodingKey` path where the variable
    /// value will be decode/encoded.
    let keyPath: [String]
    /// The variable declaration associated with this context.
    ///
    /// The original declaration that provides variable data.
    let declaration: Decl
    /// The variable data and additional metadata.
    ///
    /// The variable data is tracked for registrations,
    /// and code generation per variable.
    let variable: Var

    /// Creates a new registration with provided parameters.
    ///
    /// - Parameters:
    ///   - keyPath: The `CodingKey` path for the variable.
    ///   - declaration: The variable declaration.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Created registration.
    private init(
        keyPath: [String], declaration: Decl,
        context: some MacroExpansionContext
    ) where Decl.Variable == Var {
        self.keyPath = keyPath
        self.declaration = declaration
        self.variable = declaration.codableVariable(in: context)
    }

    /// Creates a new registration with provided parameters.
    ///
    /// - Parameters:
    ///   - keyPath: The `CodingKey` path for the variable.
    ///   - declaration: The variable declaration.
    ///   - variable: The variable data.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Created registration.
    private init(keyPath: [String], declaration: Decl, variable: Var) {
        self.keyPath = keyPath
        self.declaration = declaration
        self.variable = variable
    }

    /// Creates a new registration with provided parameters.
    ///
    /// Creates context with provided parameters and uses variable
    /// provided by declaration and variable name as `CodingKey`
    /// path in newly created registration.
    ///
    /// - Parameters:
    ///   - declaration: The variable declaration.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Created registration.
    init(
        declaration: Decl, context: some MacroExpansionContext
    ) where Decl.Variable == Var, Var: NamedVariable {
        self.declaration = declaration
        self.variable = declaration.codableVariable(in: context)
        self.keyPath = [CaseMap.Key.name(for: variable.name).text]
    }

    /// Update the `CodingKey` path in this registration
    /// with provided `CodingKey` path.
    ///
    /// Creates a new registration with the provided `CodingKey`
    /// path, carrying forward previous context and variable data.
    ///
    /// - Parameter keyPath: The new `CodingKey` path.
    /// - Returns: Newly created registration with updated
    ///   `CodingKey` path.
    func updating(with keyPath: [String]) -> Self {
        return .init(
            keyPath: keyPath, declaration: declaration, variable: variable
        )
    }

    /// Update the variable data in this registration with provided data.
    ///
    /// Creates a new registration with the provided variable data,
    /// carrying forward previous context and `CodingKey` path.
    ///
    /// - Parameter variable: The new variable data.
    /// - Returns: Newly created registration with updated variable data.
    func updating<V: Variable>(with variable: V) -> Registration<Decl, V> {
        return .init(
            keyPath: keyPath, declaration: declaration, variable: variable
        )
    }
}
