@_implementationOnly import SwiftSyntaxMacros

/// A `Variable` representing data that can be initialized.
///
/// The initialization returned can be used to generate expansion
/// for memberwise initializer.
protocol InitializableVariable<CodingLocation, Generated, Initialization>:
    Variable
{
    /// A type representing the initialization of this variable.
    ///
    /// Represents the initialization type of this variable.
    associatedtype Initialization
    /// Indicates the initialization type for this variable.
    ///
    /// Indicates whether initialization data for variable.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(in context: some MacroExpansionContext) -> Initialization
}
