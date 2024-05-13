import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with decodable/encodable
/// variable.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
package protocol Variable<CodingLocation, Generated> {
    /// The decoding/encoding location type.
    associatedtype CodingLocation
    /// The generated decoding/encoding syntax type.
    associatedtype Generated

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Individual implementation can customize decoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: CodingLocation
    ) -> Generated

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Individual implementation can customize encoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: CodingLocation
    ) -> Generated
}

/// A type representing data associated with variable with name.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
package protocol NamedVariable<CodingLocation, Generated>: Variable {
    /// The name of the variable.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   let variable: String = "data"
    ///   ```
    ///   the `name` will be `variable`.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   (_ variable: String = "data")
    ///   ```
    ///   the `name` will be `variable`.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   case variable = "data"
    ///   ```
    ///   the `name` will be `variable`.
    var name: TokenSyntax { get }
}

/// A type representing data associated with variable with name and value.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
package protocol ValuedVariable<CodingLocation, Generated>: NamedVariable {
    /// The value of the variable.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   let variable: String = "data"
    ///   ```
    ///   the `value` will be `"data"`.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   (_ variable: String = "data")
    ///   ```
    ///   the `value` will be `"data"`.
    var value: ExprSyntax? { get }
}

/// A type representing data associated with variable that can be
/// conditionally decoded/encoded.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
///
/// * The variable should be decoded if `decode` property returns `nil`/`true`.
/// * The variable should be encoded if `encode` property returns `nil`/`true`.
package protocol ConditionalVariable<CodingLocation, Generated>: Variable {
    /// Whether the variable is to
    /// be decoded.
    ///
    /// If `nil` is returned, variable
    /// is decoded by default.
    var decode: Bool? { get }
    /// Whether the variable is to
    /// be encoded.
    ///
    /// If `nil` is returned, variable
    /// is encoded by default.
    var encode: Bool? { get }
    /// The arguments passed to encoding condition.
    ///
    /// The encoding condition takes these arguments and evaluates to
    /// `true` or `false` based on which encoding is decided.
    var conditionArguments: LabeledExprListSyntax { get }
}

/// A `Variable` representing data that can be initialized.
///
/// The initialization returned can be used to generate expansion
/// for memberwise initializer.
package protocol InitializableVariable<
    CodingLocation, Generated, Initialization
>:
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
