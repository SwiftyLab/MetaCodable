import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with an associated variable
/// inside enum-case declarations.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
package protocol AssociatedVariable<Initialization>: PropertyVariable
where Initialization: RequiredVariableInitialization {
    /// The label of the variable.
    ///
    /// - For a declaration:
    ///   ```swift
    ///   (_ variable: String = "data")
    ///   ```
    ///   the `label` will be `_`.
    var label: TokenSyntax? { get }
}
