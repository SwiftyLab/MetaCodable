import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// with two separate `HelperCoder`s.
///
/// This type can be used to use separate `HelperCoder`s
/// for decoding and encoding.
public struct ConditionalCoder<D: HelperCoder, E: HelperCoder>: HelperCoder
where D.Coded == E.Coded {
    /// The `HelperCoder` used for decoding.
    @usableFromInline
    internal let decoder: D
    /// The `HelperCoder` used for encoding.
    @usableFromInline
    internal let encoder: E

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// conditionally with provided decoder/encoder respectively.
    ///
    /// The provided decoder is used only for decoding
    /// and encoder only for encoding.
    ///
    /// - Parameters:
    ///   - decoder: The `HelperCoder` used for decoding.
    ///   - encoder: The `HelperCoder` used for encoding.
    public init(decoder: D, encoder: E) {
        self.decoder = decoder
        self.encoder = encoder
    }

    /// Decodes using the decode specific `HelperCoder`
    /// from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded value.
    /// - Throws: If the underlying `HelperCoder` throws error.
    @inlinable
    public func decode(from decoder: Decoder) throws -> D.Coded {
        return try self.decoder.decode(from: decoder)
    }

    /// Decodes optional value using the decode specific
    /// `HelperCoder` from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded optional value.
    /// - Throws: If the underlying `HelperCoder` throws error.
    @inlinable
    public func decodeIfPresent(from decoder: Decoder) throws -> D.Coded? {
        return try self.decoder.decodeIfPresent(from: decoder)
    }

    /// Encodes using the encode specific `HelperCoder`
    /// from the given `encoder`.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If the underlying `HelperCoder` throws error.
    @inlinable
    public func encode(_ value: E.Coded, to encoder: Encoder) throws {
        try self.encoder.encode(value, to: encoder)
    }

    /// Encodes optional value using the encode specific
    /// `HelperCoder` from the given `encoder`.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If the underlying `HelperCoder` throws error.
    @inlinable
    public func encodeIfPresent(_ value: E.Coded?, to encoder: Encoder) throws {
        try self.encoder.encodeIfPresent(value, to: encoder)
    }
}
