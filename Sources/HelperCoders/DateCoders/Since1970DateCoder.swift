import Foundation
import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// UNIX timestamp.
///
/// This type can be used to decode/encode dates
/// in terms of interval since midnight UTC on
/// January 1st, 1970.
public struct Since1970DateCoder: HelperCoder {
    /// The UNIX timestamp interval seconds unit.
    ///
    /// The seconds unit since midnight UTC on
    /// January 1st, 1970.
    public enum IntervalType {
        /// The interval is in seconds since
        /// midnight UTC on January 1st, 1970.
        case seconds
        /// The interval is in milliseconds since
        /// midnight UTC on January 1st, 1970.
        case milliseconds
        /// The interval is in microseconds since
        /// midnight UTC on January 1st, 1970.
        case microseconds
        /// The interval is in nanoseconds since
        /// midnight UTC on January 1st, 1970.
        case nanoseconds

        /// The value for division to convert
        /// interval into seconds.
        @usableFromInline
        internal var conversion: TimeInterval {
            switch self {
            case .seconds:
                return 1
            case .milliseconds:
                return 1_000
            case .microseconds:
                return 1_000_000
            case .nanoseconds:
                return 1_000_000_000
            }
        }
    }

    /// The interval unit type.
    @usableFromInline
    internal let type: IntervalType

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// UNIX timestamp.
    ///
    /// Created instance can be used to decode/encode dates
    /// in terms of interval since midnight UTC on
    /// January 1st, 1970.
    ///
    /// - Parameter type: The interval unit type.
    public init(intervalType type: IntervalType = .seconds) {
        self.type = type
    }

    /// Decodes UNIX timestamp from the given `decoder`.
    ///
    /// The `Double` data type is decoded and converted
    /// to date as interval since midnight UTC on
    /// January 1st, 1970.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The date decoded.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the decoded data
    ///   isn't `Double` type.
    public func decode(from decoder: Decoder) throws -> Date {
        let interval = try TimeInterval(from: decoder)
        return Date(timeIntervalSince1970: interval / type.conversion)
    }

    /// Encodes UNIX timestamp to the given `encoder`.
    ///
    /// Encodes interval data since midnight UTC on
    /// January 1st, 1970.
    ///
    /// - Parameters:
    ///   - value: The date to encode.
    ///   - encoder: The encoder to write data to.
    @inlinable
    public func encode(_ value: Date, to encoder: Encoder) throws {
        try (value.timeIntervalSince1970 * type.conversion).encode(to: encoder)
    }
}
