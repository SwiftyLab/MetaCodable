import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A variable value containing helper expression for decoding/encoding.
///
/// The `HelperCodedVariable` customizes decoding and encoding
/// by using the helper instance expression provided during initialization.
struct HelperCodedVariable<Wrapped>: ComposedVariable, PropertyVariable
where Wrapped: DefaultPropertyVariable {
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

    /// The value wrapped by this instance.
    ///
    /// Only default implementation provided with
    /// `BasicVariable` can be wrapped
    /// by this instance.
    let base: Wrapped
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

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Always `false` for this type.
    var requireDecodable: Bool? { false }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Always `false` for this type.
    var requireEncodable: Bool? { false }

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
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, defMethod) = codingTypeMethod(forMethod: "decode")
        switch location {
        case .coder(let decoder, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                \(decodePrefix)\(name) = try \(options.expr).\(method)(from: \(decoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                \(decodePrefix)\(name) = try \(options.expr).\(method)(from: \(container), forKey: \(key))
                """
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
        to location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, defMethod) = codingTypeMethod(forMethod: "encode")
        switch location {
        case .coder(let encoder, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                try \(options.expr).\(method)(\(encodePrefix)\(name), to: \(encoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                try \(options.expr).\(method)(\(encodePrefix)\(name), to: &\(container), atKey: \(key))
                """
            }
        }
    }
}

extension HelperCodedVariable: InitializableVariable
where Wrapped: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Wrapped.Initialization
}

extension HelperCodedVariable: AssociatedVariable
where Wrapped: AssociatedVariable {}

/// A `Variable` type representing that doesn't customize
/// decoding/encoding implementation.
///
/// `BasicPropertyVariable` confirms to this type since it doesn't
/// customize decoding/encoding implementation from Swift standard library.
///
/// `ComposedVariable`'s may confirm to this if no decoding/encoding
/// customization added on top of underlying variable and wrapped variable
/// also confirms to this type.
protocol DefaultPropertyVariable: PropertyVariable {}
