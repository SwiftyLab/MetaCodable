import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// basic value types.
///
/// This type can be used to decode/encode dates
/// basic value types, i.e. `Bool`, `Int`, `String` etc.
public struct ValueCoder<Strategy: ValueCodingStrategy>: HelperCoder {
    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// basic value types.
    ///
    /// The `Strategy` passed is used for decoding/encoding.
    public init() {}

    /// Decodes value with the provided `Strategy` from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded basic value.
    ///
    /// - Throws: If the provided `Strategy` fails decoding.
    @inlinable
    public func decode(from decoder: Decoder) throws -> Strategy.Value {
        return try Strategy.decode(from: decoder)
    }

    /// Encodes value with the provided `Strategy` to the given `encoder`.
    ///
    /// - Parameters:
    ///   - value: The decoded basic value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If the provided `Strategy` fails encoding.
    @inlinable
    public func encode(_ value: Strategy.Value, to encoder: Encoder) throws {
        return try Strategy.encode(value, to: encoder)
    }
}

/// A type that helps to decode and encode underlying ``Value`` type
/// from provided `decoder` and to provided `encoder` respectively.
///
/// This type can be used with ``ValueCoder`` to allow
/// decoding/encoding customizations basic value types,
/// i.e. `Bool`, `Int`, `String` etc.
public protocol ValueCodingStrategy {
    /// The actual type of value that is going to be decoded/encoded.
    ///
    /// This type can be any basic value type.
    associatedtype Value
    /// Decodes a value of the ``Value`` type from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: A value of the ``Value`` type.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data.
    static func decode(from decoder: Decoder) throws -> Value
    /// Encodes given value of the ``Value`` type to the provided `encoder`.
    ///
    /// By default, if the ``Value`` value confirms to `Encodable`,
    /// then encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``Value`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    static func encode(_ value: Value, to encoder: Encoder) throws
}

public extension ValueCodingStrategy where Value: Encodable {
    /// Encodes given value of the ``ValueCodingStrategy/Value`` type
    /// to the provided `encoder`.
    ///
    /// The ``ValueCodingStrategy/Value`` value is written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``ValueCodingStrategy/Value`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    static func encode(_ value: Value, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
