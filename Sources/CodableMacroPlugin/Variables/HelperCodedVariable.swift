import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A variable value containing helper expression for decoding/encoding.
///
/// The `HelperCodedVariable` customizes decoding and encoding
/// by using the helper instance expression provided during initialization.
struct HelperCodedVariable<Var: BasicCodingVariable>: ComposedVariable {
    /// The customization options for `HelperCodedVariable`.
    ///
    /// `HelperCodedVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// The helper expression used for decoding/encoding.
        ///
        /// This expression is provided during initialization and
        /// used to generate assisted decoding/encoding syntax.
        let expr: ExprSyntax
    }

    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Var.Initialization

    /// The value wrapped by this instance.
    ///
    /// Only default implementation provided with
    /// `BasicVariable` can be wrapped
    /// by this instance.
    let base: Var
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Whether the variable is to
    /// be decoded.
    ///
    /// Always `true` for this type.
    var decode: Bool? { true }
    /// Whether the variable is to
    /// be encoded.
    ///
    /// Always `true` for this type.
    var encode: Bool? { true }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses helper expression provided, to generate implementation:
    /// * For directly decoding from decoder, passes decoder directly to
    ///   helper's `decode(from:)` (or `decodeIfPresent(from:)`
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
        in _: any MacroExpansionContext,
        from location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, method) = type.codingTypeMethod(forMethod: "decode")
        switch location {
        case let .coder(decoder):
            return CodeBlockItemListSyntax {
                """
                self.\(name) = try \(options.expr).\(method)(from: \(decoder))
                """
            }
        case let .container(container, key):
            let decoder: TokenSyntax = "\(container)_\(name.raw)Decoder"
            return CodeBlockItemListSyntax {
                "let \(decoder) = try \(container).superDecoder(forKey: \(key))"
                "self.\(name) = try \(options.expr).\(method)(from: \(decoder))"
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
        in _: any MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, method) = type.codingTypeMethod(forMethod: "encode")
        switch location {
        case let .coder(encoder):
            return CodeBlockItemListSyntax {
                """
                try \(options.expr).\(method)(self.\(name), to: \(encoder))
                """
            }
        case let .container(container, key):
            let encoder: TokenSyntax = "\(container)_\(name.raw)Encoder"
            return CodeBlockItemListSyntax {
                "let \(encoder) = \(container).superEncoder(forKey: \(key))"
                "try \(options.expr).\(method)(self.\(name), to: \(encoder))"
            }
        }
    }
}

/// A `Variable` type representing that doesn't customize
/// decoding/encoding implementation.
///
/// `BasicVariable` confirms to this type since it doesn't customize
/// decoding/encoding implementation from Swift standard library.
///
/// `ComposedVariable`'s may confirm to this if no decoding/encoding
/// customization added on top of underlying variable and wrapped variable
/// also confirms to this type.
protocol BasicCodingVariable: Variable {}
