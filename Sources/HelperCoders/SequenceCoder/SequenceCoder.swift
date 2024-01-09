import MetaCodable

/// An ``/MetaCodable/HelperCoder`` that helps decoding/encoding sequence.
///
/// This type tries to decode and encode a sequence according to provided
/// ``Configuration-swift.struct`` and element ``/MetaCodable/HelperCoder``.
///
/// `DefaultSequenceElementCoding` can be used as element
/// ``/MetaCodable/HelperCoder``, if on configuration based.
/// decoding/encoding needed
public struct SequenceCoder<Sequence, ElementHelper>: HelperCoder
where
    Sequence: SequenceInitializable, ElementHelper: HelperCoder,
    Sequence.Element == ElementHelper.Coded, Sequence: Equatable
{
    /// The ``/MetaCodable/HelperCoder`` for element.
    ///
    /// Each element is decoded/encoded using this.
    public let elementHelper: ElementHelper
    /// The configuration for decoding and encoding.
    ///
    /// Provides additional decoding/encoding customizations.
    public let configuration: Configuration

    /// Create a sequence decoder and encoder based on provided data.
    ///
    /// By default, no additional customizations configuration is used.
    ///
    /// - Parameters:
    ///   - output: The resulting sequence type.
    ///   - elementHelper: The ``/MetaCodable/HelperCoder`` for element.
    ///   - configuration: The configuration for decoding and encoding.
    public init(
        output: Sequence.Type, elementHelper: ElementHelper,
        configuration: Configuration = .init()
    ) {
        self.elementHelper = elementHelper
        self.configuration = configuration
    }

    /// Create a sequence decoder and encoder based on provided data.
    ///
    /// Sequence type is inferred from provided configuration.
    ///
    /// - Parameters:
    ///   - elementHelper: The ``/MetaCodable/HelperCoder`` for element.
    ///   - configuration: The configuration for decoding and encoding.
    public init(
        elementHelper: ElementHelper, configuration: Configuration
    ) {
        self.elementHelper = elementHelper
        self.configuration = configuration
    }

    /// Create a sequence decoder and encoder based on provided data.
    ///
    /// By default, no additional customizations configuration is used.
    /// Sequence elements are decoded and encoded using
    /// `DefaultSequenceElementCoding`.
    ///
    /// - Parameters:
    ///   - output: The resulting sequence type.
    ///   - configuration: The configuration for decoding and encoding.
    public init(
        output: Sequence.Type, configuration: Configuration = .init()
    ) where ElementHelper == DefaultSequenceElementCoding<Sequence.Element> {
        self.init(
            output: Sequence.self, elementHelper: .init(),
            configuration: configuration
        )
    }

    /// Create a sequence decoder and encoder based on provided data.
    ///
    /// Sequence type is inferred from provided configuration.
    /// Sequence elements are decoded and encoded using
    /// `DefaultSequenceElementCoding`.
    ///
    /// - Parameters:
    ///   - output: The resulting sequence type.
    ///   - configuration: The configuration for decoding and encoding.
    public init(configuration: Configuration)
    where ElementHelper == DefaultSequenceElementCoding<Sequence.Element> {
        self.init(
            output: Sequence.self, elementHelper: .init(),
            configuration: configuration
        )
    }

    /// Create a array decoder and encoder based on provided data.
    ///
    /// By default, no additional customizations configuration is used.
    ///
    /// - Parameters:
    ///   - elementHelper: The ``/MetaCodable/HelperCoder`` for element.
    ///   - configuration: The configuration for decoding and encoding.
    public init(
        elementHelper: ElementHelper, configuration: Configuration = .init()
    ) where Sequence == Array<ElementHelper.Coded> {
        self.init(
            output: Sequence.self, elementHelper: elementHelper,
            configuration: configuration
        )
    }

    /// Decodes a sequence from the given `decoder`.
    ///
    /// * If ``Configuration-swift.struct/lossy-swift.property`` is set to `true`
    ///   invalid element data are ignored.
    /// * If the data format in decoder is invalid, fallback data is used
    ///   if provided, in absence of fallback data error is thrown.
    /// * If no valid element is found in decoder's container then provided
    ///   default sequence returned if provided, or empty sequence returned.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The sequence decoded.
    ///
    /// - Throws: If error handling ``configuration-swift.property``
    ///   not provided.
    public func decode(from decoder: Decoder) throws -> Sequence {
        var container: UnkeyedDecodingContainer
        do {
            container = try decoder.unkeyedContainer()
        } catch {
            guard
                let invalidDefault = configuration.invalidDefault
            else { throw error }
            return invalidDefault
        }

        var values: [Sequence.Element] = []
        values.reserveCapacity(container.count ?? 0)
        while !container.isAtEnd {
            let decoder = try container.superDecoder()
            do {
                try values.append(elementHelper.decode(from: decoder))
            } catch {
                guard !configuration.lossy else { continue }
                throw error
            }
        }

        guard
            values.isEmpty, let emptyDefault = configuration.emptyDefault
        else { return Sequence(values) }
        return emptyDefault
    }

    /// Encodes a sequence to the given `encoder`.
    ///
    /// The elements of sequence are encoded one by one
    /// in an unkeyed container.
    ///
    /// - Parameters:
    ///   - value: The data to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If encoding any element throws.
    public func encode(_ value: Sequence, to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for element in value {
            let encoder = container.superEncoder()
            try elementHelper.encode(element, to: encoder)
        }
    }
}
