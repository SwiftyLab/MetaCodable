@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxBuilder
@_implementationOnly import SwiftSyntaxMacros

/// A default variable value with basic functionalities.
///
/// The `BasicPropertyVariable` type provides default
/// decoding/encoding implementations similar to standard library
/// generated implementations.
struct BasicPropertyVariable: DefaultPropertyVariable, DeclaredVariable {
    let label: TokenSyntax?
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
    /// The value of the variable.
    ///
    /// The value is provided during
    /// initialization of this variable.
    let value: ExprSyntax?

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

    /// Whether the variable type requires
    /// `Decodable` conformance.
    ///
    /// By default set as `nil`, unless
    /// `decode` is set explicitly during
    /// initialization.
    var requireDecodable: Bool? { self.decode }
    /// Whether the variable type requires
    /// `Encodable` conformance.
    ///
    /// By default set as `nil`, unless
    /// `encode` is set explicitly during
    /// initialization.
    var requireEncodable: Bool? { self.encode }

    /// The fallback behavior when decoding fails.
    ///
    /// In the event this decoding this variable is failed,
    /// appropriate fallback would be applied.
    ///
    /// If variable is of optional type, variable will be assigned
    /// `nil` value only when missing or `null`.
    var decodingFallback: DecodingFallback {
        guard hasOptionalType else { return .throw }
        return .ifMissing("self.\(name) = nil")
    }

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
        label: TokenSyntax?, name: TokenSyntax,
        type: TypeSyntax, value: ExprSyntax?,
        decode: Bool? = nil, encode: Bool? = nil
    ) {
        self.label = label
        self.name = name
        self.type = type
        self.value = value
        self.decode = decode
        self.encode = encode
    }

    /// Creates a new variable from declaration and expansion context.
    ///
    /// Reads the property data from the declaration provided.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    init(
        from decl: PropertyDeclSyntax, in context: some MacroExpansionContext
    ) {
        self.label = nil
        self.name =
            decl.binding.pattern.as(IdentifierPatternSyntax.self)!
            .identifier.trimmed
        self.type = decl.type
        self.value = decl.binding.initializer?.value
        self.decode = nil
        self.encode = nil
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
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        switch location {
        case .coder(let decoder, let passedMethod):
            let optionalToken: TokenSyntax =
                if passedMethod?.trimmedDescription == "decodeIfPresent" {
                    "?"
                } else {
                    ""
                }
            return CodeBlockItemListSyntax {
                """
                self.\(name) = try \(type)\(optionalToken)(from: \(decoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let (type, defMethod) = codingTypeMethod(forMethod: "decode")
            let method = passedMethod ?? defMethod
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
        to location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        switch location {
        case .coder(let encoder, _):
            return CodeBlockItemListSyntax {
                """
                try self.\(name).encode(to: \(encoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let (_, defMethod) = codingTypeMethod(forMethod: "encode")
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                try \(container).\(method)(self.\(name), forKey: \(key))
                """
            }
        }
    }
}

extension BasicPropertyVariable: InitializableVariable {
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
    ) -> RequiredInitialization {
        let param: FunctionParameterSyntax =
            if hasOptionalType {
                "\(name): \(type) = nil"
            } else {
                "\(name): \(type)"
            }
        return .init(param: param, code: "self.\(name) = \(name)")
    }
}
