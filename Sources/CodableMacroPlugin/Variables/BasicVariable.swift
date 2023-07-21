import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// A default variable value with basic functionalities.
///
/// The `BasicVariable` type provides default
/// decoding/encoding implementations similar to
/// standard library generated implementations.
struct BasicVariable: Variable {
    /// The name of this variable.
    ///
    /// The name is provided during
    /// initialization of this variable.
    let name: TokenSyntax
    /// The type of the variable.
    ///
    /// The type is provided during
    /// initialization of this variable.
    let type: TypeSyntax

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Uses default decoding approaches:
    /// * For directly decoding from decoder, uses current type's
    ///   `init(from:)` initializer.
    /// * For decoding from container, uses current type with container's
    ///   `decode(_:forKey:)` (or `decodeIfPresent(_:forKey:)`
    ///   for optional types) methods.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        switch location {
        case .coder(let decoder):
            return CodeBlockItemListSyntax {
                """
                self.\(name) = try \(type)(from: \(decoder))
                """
            }
        case .container(let container, let key):
            let (type, method) = type.codingTypeMethod(forMethod: "decode")
            return CodeBlockItemListSyntax {
                """
                self.\(name) = try \(container).\(method)(\(type).self, forKey: \(key))
                """
            }
        }
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses default decoding approaches:
    /// * For directly encoding to encoder, uses current type's
    ///   `encode(to:)` method.
    /// * For encoding from container, uses current name with container's
    ///   `encode(_:forKey:)` (or `encodeIfPresent(_:forKey:)`
    ///   for optional types) methods.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        switch location {
        case .coder(let encoder):
            return CodeBlockItemListSyntax {
                """
                try self.\(name).encode(to: \(encoder))
                """
            }
        case .container(let container, let key):
            let (_, method) = type.codingTypeMethod(forMethod: "encode")
            return CodeBlockItemListSyntax {
                """
                try \(container).\(method)(self.\(name), forKey: \(key))
                """
            }
        }
    }
}
