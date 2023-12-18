@_implementationOnly import SwiftSyntaxMacros

/// A `Variable` type representing that can be read from syntax declaration.
///
/// This type informs how the variable can b e read from a syntax declaration.
protocol DeclaredVariable<Decl, CodingLocation, Generated>: Variable {
    /// The declaration type for this variable.
    associatedtype Decl
    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses the declaration to read variable specific data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    init(from decl: Decl, in context: some MacroExpansionContext)
}
