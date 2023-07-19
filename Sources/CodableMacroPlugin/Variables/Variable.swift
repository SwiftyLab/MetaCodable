import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with
/// a variable inside type declarations.
///
/// This type informs how the variable needs
/// to be initialized, decoded and encoded
/// in the macro code generation phase.
///
/// This type also informs whether the variable
/// is necessary to the generated code during
/// the registration phase.
protocol Variable {
    /// The name of the variable.
    ///
    /// For a declaration:
    /// ```swift
    /// let variable: String
    /// ```
    /// the `name` will be `variable`.
    var name: TokenSyntax { get }
    /// The type of the variable.
    ///
    /// For a declaration:
    /// ```swift
    /// let variable: String
    /// ```
    /// the `type` will be `String`.
    var type: TypeSyntax { get }
    /// Whether the variable is needed
    /// for final code generation.
    ///
    /// If the variable can not be initialized and
    /// not asked to be encoded explicitly.
    var canBeRegistered: Bool { get }

    /// Indicates the initialization type for this variable.
    ///
    /// Indicates whether initialization is required, optional
    /// or needs to be skipped. Also, provides default
    /// initialization data if applicable.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> VariableInitialization
    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Individual implementation can customize decoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax
    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Individual implementation can customize encoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax
}

extension Variable {
    /// Whether the variable is needed
    /// for final code generation.
    ///
    /// If the variable can not be initialized and
    /// not asked to be encoded explicitly.
    ///
    /// By default, all variables are needed for
    /// final code generation.
    var canBeRegistered: Bool { true }

    /// Indicates the initialization type for this variable.
    ///
    /// Indicates whether initialization is required, optional
    /// or needs to be skipped. Also, provides default
    /// initialization data if applicable.
    ///
    /// By default, only optional variables are provided
    /// with default initialization value `nil`.
    ///
    /// - Parameter context: The context in which to perform
    ///                      the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> VariableInitialization {
        let funcParam: FunctionParameterSyntax = if type.isOptional {
            "\(name): \(type) = nil"
        } else {
            "\(name): \(type)"
        }
        return .required(funcParam, "self.\(name) = \(name)")
    }
}
