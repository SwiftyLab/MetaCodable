/// A type that helps to decode and encode underlying ``Coded`` type
/// from provided `decoder` and to provided `encoder` respectively.
///
/// This type can be used with ``CodablePath(helper:_:)``,
/// ``CodableCompose(helper:)`` and their variations to allow
/// decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types.
///
/// - Tip: Use this type to refactor scenarios where `propertyWraaper`s
///      were used to have custom decoding/encoding functionality.
public protocol ExternalHelperCoder {
    /// The actual type of value that is going to be decoded/encoded.
    ///
    /// This type can be both `Codable` and non-`Codable` types.
    associatedtype Coded

    /// Decodes a value of the ``Coded`` type from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: A value of the ``Coded`` type.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data.
    func decode(from decoder: Decoder) throws -> Coded
    /// Decodes an optional value of the ``Coded`` type from
    /// the given `decoder`, if present.
    ///
    /// Uses ``decode(from:)`` implementation by default
    /// to get value and returns `nil` if any error thrown.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: An optional value of the ``Coded`` type.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data.
    func decodeIfPresent(from decoder: Decoder) throws -> Coded?

    /// Encodes given value of the ``Coded`` type to the provided `encoder`.
    ///
    /// If the ``Coded`` value confirms to `Encodable`, then encoding is
    /// performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encode(_ value: Coded, to encoder: Encoder) throws
    /// Encodes given optional value of the ``Coded`` type to the provided
    /// `encoder` if it is not `nil`.
    ///
    /// If the ``Coded`` value confirms to `Encodable`, then encoding is
    /// performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encodeIfPresent(_ value: Coded?, to encoder: Encoder) throws
}

public extension ExternalHelperCoder {
    /// Decodes an optional value of the ``ExternalHelperCoder/Coded``
    /// type from the given `decoder`, if present.
    ///
    /// Uses ``decode(from:)`` implementation to get value
    /// and returns `nil` if any error thrown.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: An optional value of the ``ExternalHelperCoder/Coded`` type.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data.
    func decodeIfPresent(from decoder: Decoder) throws -> Coded? {
        return try? self.decode(from: decoder)
    }

    /// Encodes given value of the ``ExternalHelperCoder/Coded`` type
    /// to the provided `encoder`.
    ///
    /// If the ``ExternalHelperCoder/Coded`` value confirms to `Encodable`,
    /// then encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``ExternalHelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encode(_ value: Coded, to encoder: Encoder) throws {
        try (value as? Encodable)?.encode(to: encoder)
    }

    /// Encodes given optional value of the ``ExternalHelperCoder/Coded`` type
    /// to the provided `encoder`, if it is not `nil`.
    ///
    /// If the ``ExternalHelperCoder/Coded`` value confirms to `Encodable`,
    /// then encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``ExternalHelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encodeIfPresent(_ value: Coded?, to encoder: Encoder) throws {
        guard let value else { return }
        try self.encode(value, to: encoder)
    }
}

public extension ExternalHelperCoder where Coded: Encodable {
    /// Encodes given value of the ``ExternalHelperCoder/Coded`` type
    /// to the provided `encoder`.
    ///
    /// The ``ExternalHelperCoder/Coded`` value is written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``ExternalHelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encode(_ value: Coded, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
