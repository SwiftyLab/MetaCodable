import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// non-confirming floating point values.
///
/// This type can be used to decode/encode exceptional
/// floating-point values from a specified string representation.
public struct NonConformingCoder<Float>: HelperCoder
where Float: FloatingPoint & Codable & LosslessStringConvertible {
    /// The value representing positive infinity.
    private let positiveInfinity: String
    /// The value representing negative infinity.
    private let negativeInfinity: String
    /// The value representing not-a-number.
    private let nan: String

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// exceptional floating-point values matching provided
    /// string representations.
    ///
    /// - Parameters:
    ///   - positiveInfinity: The value representing positive infinity.
    ///   - negativeInfinity: The value representing negative infinity.
    ///   - nan: The value representing not-a-number.
    public init(
        positiveInfinity: String,
        negativeInfinity: String,
        nan: String
    ) {
        self.positiveInfinity = positiveInfinity
        self.negativeInfinity = negativeInfinity
        self.nan = nan
    }

    /// Decodes exceptional floating-point values from a specified
    /// string representation.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The float value decoded.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the encountered
    ///   string representation can't be converted to float and
    ///   doesn't match any of the boundaries of this instance.
    public func decode(from decoder: Decoder) throws -> Float {
        guard let strValue = try? String(from: decoder) else {
            return try .init(from: decoder)
        }

        switch strValue {
        case positiveInfinity: return .infinity
        case negativeInfinity: return -.infinity
        case nan: return .nan
        default:
            guard let value = Float(strValue) else {
                throw DecodingError.typeMismatch(
                    String.self,
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: """
                            "\(strValue)" couldn't convert to float \(Float.self)
                            """
                    )
                )
            }
            return value
        }
    }

    /// Encodes exceptional floating-point values to a specified
    /// string representation.
    ///
    /// If the float value doesn't match the boundaries actual
    /// value is encoded instead of string representation.
    ///
    /// - Parameters:
    ///   - value: The float value to encode.
    ///   - encoder: The encoder to write data to.
    public func encode(_ value: Float, to encoder: Encoder) throws {
        switch value {
        case .infinity:
            try positiveInfinity.encode(to: encoder)
        case -.infinity:
            try negativeInfinity.encode(to: encoder)
        case _ where value.isNaN:
            try nan.encode(to: encoder)
        default:
            try value.encode(to: encoder)
        }
    }
}
