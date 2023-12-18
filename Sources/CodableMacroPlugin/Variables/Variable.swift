@_implementationOnly import SwiftSyntaxMacros

/// A type representing data associated with decodable/encodable
/// variable.
///
/// This type informs how the variable needs to be decoded/encoded
/// in the macro expansion phase.
protocol Variable<CodingLocation, Generated> {
    /// The decoding/encoding location type.
    associatedtype CodingLocation
    /// The generated decoding/encoding syntax type.
    associatedtype Generated

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Individual implementation can customize decoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: CodingLocation
    ) -> Generated

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Individual implementation can customize encoding strategy.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: CodingLocation
    ) -> Generated
}
