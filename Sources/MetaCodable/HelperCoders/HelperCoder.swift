/// A type that helps to decode and encode underlying ``Coded`` type
/// from provided `decoder` and to provided `encoder` respectively.
///
/// This type can be used with ``CodedBy(_:)`` to allow
/// decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types.
///
/// - Tip: Use this type to refactor scenarios where `propertyWrapper`s
///   were used to have custom decoding/encoding functionality.
public protocol HelperCoder {
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

    /// Decodes a value of the ``Coded`` type from the given `container`
    /// and specified `key`.
    ///
    /// Uses ``decode(from:)`` implementation by default
    /// to get value from the `decoder` at the specified key.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: A value of the ``Coded`` type.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    func decode<DecodingContainer: KeyedDecodingContainerProtocol>(
        from container: DecodingContainer,
        forKey key: DecodingContainer.Key
    ) throws -> Coded
    /// Decodes an optional value of the ``Coded`` type from
    /// the given `container` and specified `key`, if present.
    ///
    /// Uses ``decodeIfPresent(from:)`` implementation by default
    /// to get value if any value exists at specified key,
    /// otherwise returns `nil` if any error thrown.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: An optional value of the ``Coded`` type.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    func decodeIfPresent<DecodingContainer: KeyedDecodingContainerProtocol>(
        from container: DecodingContainer,
        forKey key: DecodingContainer.Key
    ) throws -> Coded?

    /// Encodes given value of the ``Coded`` type to the provided `encoder`.
    ///
    /// By default, of the ``Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
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
    /// By default, of the ``Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encodeIfPresent(_ value: Coded?, to encoder: Encoder) throws

    /// Encodes given value of the ``Coded`` type to the provided `container`
    /// at the specified `key`.
    ///
    /// By default, of the ``Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``Coded`` value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encode<EncodingContainer: KeyedEncodingContainerProtocol>(
        _ value: Coded,
        to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws
    /// Encodes given optional value of the ``Coded`` type to the provided
    /// `container` at the specified `key`, if it is not `nil`.
    ///
    /// By default, of the ``Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``Coded`` value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    func encodeIfPresent<EncodingContainer: KeyedEncodingContainerProtocol>(
        _ value: Coded?,
        to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws
}

public extension HelperCoder {
    /// Decodes an optional value of the ``HelperCoder/Coded``
    /// type from the given `decoder`, if present.
    ///
    /// Uses ``decode(from:)`` implementation to get value
    /// and returns `nil` if any error thrown.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: An optional value of the ``HelperCoder/Coded`` type.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    func decodeIfPresent(from decoder: Decoder) throws -> Coded? {
        return try? self.decode(from: decoder)
    }

    /// Decodes a value of the ``HelperCoder/Coded`` type from the given
    /// `container` and specified `key`.
    ///
    /// Uses ``decode(from:)`` implementation by default
    /// to get value from the `decoder` at the specified key.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: A value of the ``HelperCoder/Coded`` type.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    func decode<DecodingContainer: KeyedDecodingContainerProtocol>(
        from container: DecodingContainer,
        forKey key: DecodingContainer.Key
    ) throws -> Coded {
        return try self.decode(from: container.superDecoder(forKey: key))
    }

    /// Decodes an optional value of the ``HelperCoder/Coded`` type from
    /// the given `container` and specified `key`, if present.
    ///
    /// Uses ``decodeIfPresent(from:)`` implementation by default
    /// to get value if any value exists at specified key,
    /// otherwise returns `nil` if any error thrown.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: An optional value of the ``HelperCoder/Coded`` type.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    func decodeIfPresent<DecodingContainer: KeyedDecodingContainerProtocol>(
        from container: DecodingContainer,
        forKey key: DecodingContainer.Key
    ) throws -> Coded? {
        guard let isNil = try? container.decodeNil(forKey: key), !isNil
        else { return nil }
        return try self.decode(from: container, forKey: key)
    }

    /// Encodes given value of the ``HelperCoder/Coded`` type
    /// to the provided `encoder`.
    ///
    /// If the ``HelperCoder/Coded`` value confirms to `Encodable`,
    /// then encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``HelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    func encode(_ value: Coded, to encoder: Encoder) throws {
        try (value as? Encodable)?.encode(to: encoder)
    }

    /// Encodes given optional value of the ``HelperCoder/Coded`` type
    /// to the provided `encoder`, if it is not `nil`.
    ///
    /// If the ``HelperCoder/Coded`` value confirms to `Encodable`,
    /// then encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``HelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    func encodeIfPresent(_ value: Coded?, to encoder: Encoder) throws {
        guard let value else { return }
        try self.encode(value, to: encoder)
    }

    /// Encodes given value of the ``HelperCoder/Coded`` type to the provided `container`
    /// at the specified `key`.
    ///
    /// By default, of the ``HelperCoder/Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``HelperCoder/Coded`` value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    func encode<EncodingContainer: KeyedEncodingContainerProtocol>(
        _ value: Coded,
        to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws {
        try self.encode(value, to: container.superEncoder(forKey: key))
    }

    /// Encodes given optional value of the ``HelperCoder/Coded`` type to the provided
    /// `container` at the specified `key`, if it is not `nil`.
    ///
    /// By default, of the ``HelperCoder/Coded`` value confirms to `Encodable`, then
    /// encoding is performed. Otherwise no data written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The optional ``HelperCoder/Coded`` value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    func encodeIfPresent<EncodingContainer: KeyedEncodingContainerProtocol>(
        _ value: Coded?,
        to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws {
        guard let value else { return }
        try self.encode(value, to: &container, atKey: key)
    }
}

public extension HelperCoder where Coded: Encodable {
    /// Encodes given value of the ``HelperCoder/Coded`` type
    /// to the provided `encoder`.
    ///
    /// The ``HelperCoder/Coded`` value is written to the encoder.
    ///
    /// - Parameters:
    ///   - value: The ``HelperCoder/Coded`` value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    func encode(_ value: Coded, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
