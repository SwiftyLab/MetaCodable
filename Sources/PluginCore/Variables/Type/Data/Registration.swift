import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing variable registration for code generation.
///
/// This type contains variable and `CodingKey` data
/// that is necessary for syntax generation.
struct Registration<Decl, Key, Var: Variable> {
    /// The variable declaration associated with this context.
    ///
    /// The original declaration that provides variable data.
    let decl: Decl
    /// The `CodingKey` data for the variable.
    ///
    /// The `CodingKey` data where the variable
    /// value will be decode/encoded.
    let key: Key
    /// The variable data and additional metadata.
    ///
    /// The variable data is tracked for registrations,
    /// and code generation per variable.
    let variable: Var

    /// Creates a new registration with provided parameters.
    ///
    /// - Parameters:
    ///   - decl: The variable declaration.
    ///   - key: The `CodingKey` data for the variable.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Created registration.
    init(
        decl: Decl, key: Key,
        context: some MacroExpansionContext
    ) where Decl: VariableSyntax, Decl.Variable == Var {
        self.key = key
        self.decl = decl
        self.variable = decl.codableVariable(in: context)
    }

    /// Creates a new registration with provided parameters.
    ///
    /// - Parameters:
    ///   - decl: The variable declaration.
    ///   - key: The `CodingKey` data for the variable.
    ///   - variable: The variable data.
    ///
    /// - Returns: Created registration.
    init(decl: Decl, key: Key, variable: Var) {
        self.decl = decl
        self.key = key
        self.variable = variable
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
    func updating(with key: Key) -> Self {
        return .init(decl: decl, key: key, variable: variable)
    }

    /// Update the variable data in this registration with provided data.
    ///
    /// Creates a new registration with the provided variable data,
    /// carrying forward previous context and `CodingKey` path.
    ///
    /// - Parameter variable: The new variable data.
    /// - Returns: Newly created registration with updated variable data.
    func updating<V: Variable>(with variable: V) -> Registration<Decl, Key, V> {
        return .init(decl: decl, key: key, variable: variable)
    }
}

/// A type representing property variable registration for code generation.
///
/// This type contains variable and `CodingKey` path data that is necessary
/// for syntax generation.
typealias PathRegistration<Decl, Var> = Registration<Decl, [String], Var>
where Var: Variable

/// A type representing enum case variable registration for code generation.
///
/// This type contains variable and `CodingKey` value data that is necessary
/// for syntax generation.
typealias ExprRegistration<Decl, Var> = Registration<Decl, [ExprSyntax], Var>
where Var: Variable
