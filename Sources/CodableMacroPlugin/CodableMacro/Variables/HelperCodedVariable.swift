import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// A variable value containing helper expression for decoding/encoding.
///
/// The `HelperCodedVariable` customizes decoding and encoding
/// by using the helper instance expression provided during initialization.
struct HelperCodedVariable: Variable {
    /// The customization option for `HelperCodedVariable`.
    ///
    /// `HelperCodedVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Option {
        /// The helper expression used for decoding/encoding.
        ///
        /// This expression is provided during initialization and
        /// used to generate assisted decoding/encoding syntax.
        let expr: ExprSyntax
    }

    /// The value wrapped by this instance.
    ///
    /// Only default implementation provided with
    /// `BasicVariable` can be wrapped
    /// by this instance.
    let base: BasicVariable
    /// The option for customizations.
    ///
    /// Option is provided during initialization.
    let option: Option

    /// The name of the variable.
    ///
    /// Provides name of the underlying variable value.
    var name: TokenSyntax { base.name }
    /// The type of the variable.
    ///
    /// Provides type of the underlying variable value.
    var type: TypeSyntax { base.type }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses helper expression provided, to generate implementation:
    /// * For directly decoding from decoder, passes decoder directly to helper's
    ///   `decode(from:)` (or `decodeIfPresent(from:)`
    ///   for optional types) method.
    /// * For decoding from container, passes super-decoder at container's
    ///   provided `CodingKey` to helper's `decode(from:)`
    ///   (or `decodeIfPresent(from:)` for optional types) methods.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, method) = type.codingTypeMethod(forMethod: "decode")
        switch location {
        case .coder(let decoder):
            return CodeBlockItemListSyntax {
                """
                self.\(name) = try \(option.expr).\(method)(from: \(decoder))
                """
            }
        case .container(let container, let key):
            let decoder: TokenSyntax = "\(container)_\(name.raw)Decoder"
            return CodeBlockItemListSyntax {
                "let \(decoder) = try \(container).superDecoder(forKey: \(key))"
                "self.\(name) = try \(option.expr).\(method)(from: \(decoder))"
            }
        }
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses helper expression provided, to generate implementation:
    /// * For directly encoding to encoder, passes encoder directly to helper's
    ///   `encode(to:)` (or `encodeIfPresent(to:)`
    ///   for optional types) method.
    /// * For encoding to container, passes super-encoder at container's
    ///   provided `CodingKey` to helper's `encode(to:)`
    ///   (or `encodeIfPresent(to:)` for optional types) methods.
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
        let (_, method) = type.codingTypeMethod(forMethod: "encode")
        switch location {
        case .coder(let encoder):
            return CodeBlockItemListSyntax {
                """
                try \(option.expr).\(method)(self.\(name), to: \(encoder))
                """
            }
        case .container(let container, let key):
            let encoder: TokenSyntax = "\(container)_\(name.raw)Encoder"
            return CodeBlockItemListSyntax {
                "let \(encoder) = \(container).superEncoder(forKey: \(key))"
                "try \(option.expr).\(method)(self.\(name), to: \(encoder))"
            }
        }
    }
}
