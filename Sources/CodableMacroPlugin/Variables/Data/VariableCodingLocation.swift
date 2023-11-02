@_implementationOnly import SwiftSyntax

/// Represents the location for decoding/encoding for `Variable`s.
///
/// Represents whether `Variable`s need to decode/encode directly
/// from/to the decoder/encoder respectively or at path of a container
enum VariableCodingLocation {
    /// Represents a top-level decoding/encoding location.
    ///
    /// The variable needs to be decoded/encoded directly to the
    /// decoder/encoder provided, not nested at a `CodingKey`.
    ///
    /// - Parameter coder: The decoder/encoder
    ///   for decoding/encoding.
    case coder(_ coder: TokenSyntax)
    /// Represents decoding/encoding location at a `CodingKey`
    /// for a container.
    ///
    /// The variable needs to be decoded/encoded at the
    /// `CodingKey` inside the container provided.
    ///
    /// - Parameters:
    ///   - container: The container for decoding/encoding.
    ///   - key: The `CodingKey` inside the container.
    case container(_ container: TokenSyntax, key: ExprSyntax)
}
