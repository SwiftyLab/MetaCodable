@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing data associated with
/// a variable inside type declarations.
///
/// This type informs how the variable needs
/// to be initialized, decoded and encoded
/// in the macro code generation phase.
protocol Variable<Initialization> {
    /// A type representing the initialization of this variable.
    ///
    /// Represents the initialization type of this variable, i.e whether
    /// initialization is required, optional or can be ignored.
    associatedtype Initialization: VariableInitialization
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

    /// Whether the variable type requires
    /// `Decodable` conformance.
    ///
    /// Used for generic where clause, for
    /// `Decodable` conformance generation.
    ///
    /// If `nil` is returned, variable is used in
    /// generic where clause by default.
    var requireDecodable: Bool? { get }
    /// Whether the variable type requires
    /// `Encodable` conformance.
    ///
    /// Used for generic where clause, for
    /// `Encodable` conformance generation.
    ///
    /// If `nil` is returned, variable is used in
    /// generic where clause by default.
    var requireEncodable: Bool? { get }

    /// The fallback behavior when decoding fails.
    ///
    /// In the event this decoding this variable is failed,
    /// appropriate fallback would be applied.
    var decodingFallback: DecodingFallback { get }

    /// Indicates the initialization type for this variable.
    ///
    /// Indicates whether initialization is required, optional
    /// or needs to be skipped. Also, provides default
    /// initialization data if applicable.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: MacroExpansionContext
    ) -> Initialization
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
        in context: MacroExpansionContext,
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
        in context: MacroExpansionContext,
        to location: VariableCodingLocation
    ) -> CodeBlockItemListSyntax
}
