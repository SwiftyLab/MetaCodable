import MetaCodable

/// An enumeration of supported helper coder strategies for use with the `@Codable` macro's `commonStrategies` parameter.
///
/// Use cases such as `.valueCoder()` allow you to specify that all properties should use a particular value coding strategy
/// (e.g., `ValueCoder`) for encoding and decoding, without annotating each property individually.
public enum HelperCoderStrategy {
    /// Applies the `ValueCoder` strategy to all properties, optionally specifying additional types.
    case valueCoder(_ additionalTypes: [any ValueCodingStrategy.Type] = [])
    // Future cases can be added here
}

public extension CodableCommonStrategy {
    /// Returns a `CodableCommonStrategy` representing the use of a helper coder strategy for all properties.
    ///
    /// - Parameter helperCoderStrategy: The helper coder strategy to apply (e.g., `.valueCoder()`).
    /// - Returns: A `CodableCommonStrategy` value for use in the `commonStrategies` parameter of `@Codable`.
    static func codedBy(_ helperCoderStrategy: HelperCoderStrategy) -> Self {
        .init()
    }
}
