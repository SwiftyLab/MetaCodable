@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing data associated with variable with name.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
protocol NamedVariable<CodingLocation, Generated>: Variable {
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
    ///
    /// - For a declaration:
    ///   ```swift
    ///   case variable = "data"
    ///   ```
    ///   the `value` will be `"data"`.
    var value: ExprSyntax? { get }

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
}
