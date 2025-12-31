/// A type that conforms to all `ExpressibleBy*Literal` protocols for use in macro contexts.
///
/// This type is designed to be used only during macro expansion and compile-time processing.
/// All runtime implementations will `fatalError` to prevent accidental usage at runtime.
///
/// ## Usage
/// This type allows macros to accept literal values of any type while maintaining type safety
/// during compilation. The actual values are processed at compile-time and never instantiated
/// at runtime.
///
/// ## Warning
/// **DO NOT USE AT RUNTIME** - All initializers and methods will crash with `fatalError`.
public struct AnyCodableLiteral {
    /// Private initializer to prevent direct instantiation
    private init() {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByBooleanLiteral
extension AnyCodableLiteral: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByIntegerLiteral
extension AnyCodableLiteral: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByFloatLiteral
extension AnyCodableLiteral: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByStringLiteral
extension AnyCodableLiteral: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByExtendedGraphemeClusterLiteral
extension AnyCodableLiteral: ExpressibleByExtendedGraphemeClusterLiteral {
    public init(extendedGraphemeClusterLiteral value: String) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByUnicodeScalarLiteral
extension AnyCodableLiteral: ExpressibleByUnicodeScalarLiteral {
    public init(unicodeScalarLiteral value: String) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - ExpressibleByStringInterpolation
extension AnyCodableLiteral: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        public init(literalCapacity: Int, interpolationCount: Int) {
            fatalError(
                "AnyCodableLiteral is not for runtime usage - compile-time only"
            )
        }

        public mutating func appendLiteral(_ literal: String) {
            fatalError(
                "AnyCodableLiteral is not for runtime usage - compile-time only"
            )
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            fatalError(
                "AnyCodableLiteral is not for runtime usage - compile-time only"
            )
        }
    }

    public init(stringInterpolation: StringInterpolation) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - Additional Conformances for Completeness
extension AnyCodableLiteral: Hashable {
    public func hash(into hasher: inout Hasher) {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: Equatable {
    public static func == (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> Bool {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: CustomStringConvertible {
    public var description: String {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: CustomDebugStringConvertible {
    public var debugDescription: String {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - Comparable and Numeric Support
extension AnyCodableLiteral: Comparable {
    public static func < (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> Bool {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: AdditiveArithmetic {
    public static var zero: AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func + (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func - (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: Numeric {
    public typealias Magnitude = AnyCodableLiteral

    public var magnitude: AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func * (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func *= (lhs: inout AnyCodableLiteral, rhs: AnyCodableLiteral)
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public init?<T>(exactly source: T) where T: BinaryInteger {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: SignedNumeric {
    public static func += (lhs: inout AnyCodableLiteral, rhs: AnyCodableLiteral)
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func -= (lhs: inout AnyCodableLiteral, rhs: AnyCodableLiteral)
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func / (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static func /= (lhs: inout AnyCodableLiteral, rhs: AnyCodableLiteral)
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public static prefix func - (
        operand: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

extension AnyCodableLiteral: Strideable {
    public typealias Stride = AnyCodableLiteral

    public func distance(to other: AnyCodableLiteral) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    public func advanced(by n: AnyCodableLiteral) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}

// MARK: - Range Operator Implementations
extension AnyCodableLiteral {
    /// Closed range operator (...)
    public static func ... (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    /// Half-open range operator (..<)
    public static func ..< (
        lhs: AnyCodableLiteral, rhs: AnyCodableLiteral
    ) -> AnyCodableLiteral {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    /// One-sided range operator (...) - postfix
    public static postfix func ... (lhs: AnyCodableLiteral) -> AnyCodableLiteral
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    /// One-sided range operator (...) - prefix
    public static prefix func ... (rhs: AnyCodableLiteral) -> AnyCodableLiteral
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }

    /// One-sided range operator (..<) - prefix
    public static prefix func ..< (rhs: AnyCodableLiteral) -> AnyCodableLiteral
    {
        fatalError(
            "AnyCodableLiteral is not for runtime usage - compile-time only"
        )
    }
}
