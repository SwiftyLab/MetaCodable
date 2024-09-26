import MetaCodable

/// An `HelperCoder` that performs default decoding/encoding.
///
/// This type doesn't provide any customization and used only to opt out of
/// decoding/encoding customizations.
@_documentation(visibility: internal)
public struct DefaultSequenceElementCoding<Coded: Codable>: HelperCoder {
    /// Decodes value from the given `decoder`.
    ///
    /// Decodes the data using type's `Decodable` implementation.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded value.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    public func decode(from decoder: Decoder) throws -> Coded {
        return try Coded(from: decoder)
    }

    /// Decodes optional value from the given `decoder`.
    ///
    /// Decodes the data using optional type's `Decodable` implementation.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The optional decoded value.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    public func decodeIfPresent(from decoder: Decoder) throws -> Coded? {
        return try Coded?(from: decoder)
    }

    /// Decodes value of the from the given `container` and specified `key`.
    ///
    /// Uses container's default `decode(_:forKey:)` implementation
    /// to get value from the `container` at the specified `key`.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: The decoded value.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    public func decode<DecodingContainer: KeyedDecodingContainerProtocol>(
        from container: DecodingContainer,
        forKey key: DecodingContainer.Key
    ) throws -> Coded {
        return try container.decode(Coded.self, forKey: key)
    }

    /// Decodes optional value of the from the given `container` and
    /// specified `key`.
    ///
    /// Uses container's default `decodeIfPresent(_:forKey:)` implementation
    /// to get value from the `container` at the specified `key`.
    ///
    /// - Parameters:
    ///   - container: The container to read data from.
    ///   - key: The key for the value decoded.
    ///
    /// - Returns: The optional decoded value.
    /// - Throws: If decoding fails due to corrupted or invalid data.
    @inlinable
    public func decodeIfPresent<DecodingContainer>(
        from container: DecodingContainer, forKey key: DecodingContainer.Key
    ) throws -> Coded? where DecodingContainer: KeyedDecodingContainerProtocol {
        return try container.decodeIfPresent(Coded.self, forKey: key)
    }

    /// Encodes given value to the provided `encoder`.
    ///
    /// Decodes the value using type's `Encodable` implementation.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    public func encode(_ value: Coded, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }

    /// Encodes given optional value to the provided `encoder`.
    ///
    /// Decodes the optional value using optional type's `Encodable`
    /// implementation.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    public func encodeIfPresent(_ value: Coded?, to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }

    /// Encodes given value of to the provided `container` at the specified
    /// `key`.
    ///
    /// Uses container's default `encode(_:forKey:)` implementation
    /// to write value to the `container` at the specified `key`.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    public func encode<EncodingContainer: KeyedEncodingContainerProtocol>(
        _ value: Coded, to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws {
        try container.encode(value, forKey: key)
    }

    /// Encodes given optional value of to the provided `container`
    ///  at the specified `key`.
    ///
    /// Uses container's default `encodeIfPresent(_:forKey:)` implementation
    /// to write optional value to the `container` at the specified `key`.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - container: The container to write data to.
    ///   - key: The key to write data at.
    ///
    /// - Throws: If any values are invalid for the given encoder’s format.
    @inlinable
    public func encodeIfPresent<EncodingContainer>(
        _ value: Coded?, to container: inout EncodingContainer,
        atKey key: EncodingContainer.Key
    ) throws where EncodingContainer: KeyedEncodingContainerProtocol {
        try container.encodeIfPresent(value, forKey: key)
    }
}
