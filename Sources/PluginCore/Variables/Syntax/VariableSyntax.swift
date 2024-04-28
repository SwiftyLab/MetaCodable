import SwiftSyntaxMacros

/// A type representing associated `Variable` declaration.
///
/// This type can be used by associated `Variable` type to read data.
protocol VariableSyntax<Variable> {
    /// The `Variable` type this syntax represents.
    associatedtype Variable: DeclaredVariable where Variable.Decl == Self
    /// Creates `Variable` from current syntax.
    ///
    /// Passes declaration data to `Variable` to read and initialize.
    ///
    /// - Parameter context: The context in which to perform the macro expansion.
    /// - Returns: The `Variable` instance.
    func codableVariable(in context: some MacroExpansionContext) -> Variable
}

extension VariableSyntax {
    /// Creates `Variable` from current syntax.
    ///
    /// Passes declaration data to `Variable` to read and initialize.
    ///
    /// - Parameter context: The context in which to perform the macro expansion.
    /// - Returns: The `Variable` instance.
    func codableVariable(in context: some MacroExpansionContext) -> Variable {
        return .init(from: self, in: context)
    }
}
