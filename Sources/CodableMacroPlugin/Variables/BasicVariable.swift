import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

/// A default variable value with basic functionalities.
///
/// The `BasicVariable` type provides default
/// decoding/encoding implementations similar to
/// standard library generated implementations.
struct BasicVariable: BasicCodingVariable {
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

    /// Whether the variable is to
    /// be decoded.
    ///
    /// By default set as `nil`,
    /// unless value passed explicitly
    /// during initialization.
    let decode: Bool?
    /// Whether the variable is to
    /// be encoded.
    ///
    /// By default set as `nil`,
    /// unless value passed explicitly
    /// during initialization.
    let encode: Bool?

    /// Creates a new variable with provided data.
    ///
    /// Basic implementation for this variable provided
    /// matching Swift standard library generated code.
    ///
    /// - Parameters:
    ///   - name: The name of this variable.
    ///   - type: The type of the variable.
    ///   - decode: Whether to decode explicitly.
    ///   - encode: Whether to encode explicitly.
    ///
    /// - Returns: Newly created variable.
    init(
        name: TokenSyntax, type: TypeSyntax,
        decode: Bool? = nil, encode: Bool? = nil
    ) {
        self.name = name
        self.type = type
        self.decode = decode
        self.encode = encode
    }

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
        in context: MacroExpansionContext
    ) -> RequiredInitialization {
        let param: FunctionParameterSyntax = if type.isOptional {
            "\(name): \(type) = nil"
        } else {
            "\(name): \(type)"
        }
        return .init(param: param, code: "self.\(name) = \(name)")
    }

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
        in context: MacroExpansionContext,
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
        in context: MacroExpansionContext,
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

extension BasicVariable: DefaultOptionComposedVariable {
    /// The value wrapped by this instance.
    ///
    /// Provides current variable as is.
    var base: BasicVariable { self }

    /// Creates a new instance from provided variable value.
    ///
    /// Uses the provided value as the newly created variable.
    ///
    /// - Parameter base: The underlying variable value.
    /// - Returns: The newly created variable.
    init(base: BasicVariable) {
        self = base
    }
}
