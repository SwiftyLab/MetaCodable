// CodableCommonStrategy.swift
// Defines the CodableCommonStrategy struct for commonStrategies parameter in @Codable macro.

/// A marker type used to represent a common type conversion strategy for the `@Codable` macro.
///
/// `CodableCommonStrategy` is used as the element type for the `commonStrategies` parameter in the
/// `@Codable` macro. It allows users to specify strategies (such as value coding) that should be
/// automatically applied to all properties of a type, so that users do not have to annotate each property
/// individually. The macro system interprets these strategies and injects the appropriate coding logic
/// during macro expansion.
///
/// Example usage:
/// ```swift
/// @Codable(commonStrategies: [.codedBy(.valueCoder())])
/// struct MyModel {
///     let int: Int
///     let string: String
/// }
/// ```
public struct CodableCommonStrategy {
    // Only allow MetaCodable to construct
    package init() {}
}
