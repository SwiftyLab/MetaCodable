/// An ``HelperCoder`` that helps decoding/encoding lossy sequence.
///
/// This type tries to decode a sequence from provided decoder's container
/// only accepting valid data and ignoring invalid/corrupt data instead of
/// throwing error aborting decoding of entire sequence.
///
/// If no valid data could be decoded, provided default sequence is used.
///
/// - Warning: If data in decoder is not of an unkeyed container format
///   ``decode(from:)`` can fail with error.
@available(*, deprecated, message: "Use SequenceCoder from HelperCoders")
public struct LossySequenceCoder<S: SequenceInitializable>: HelperCoder
where S: Codable, S.Element: Codable {
    /// The default value to use
    /// when no valid data decoded.
    private let `default`: S

    /// Creates a new instance of ``HelperCoder`` that decodes
    /// lossy sequence of provided type and with given
    /// default values.
    ///
    /// The default value is used when no valid data decoded
    /// for sequence.
    ///
    /// - Parameter default: The default value.
    public init(default: S = .init([])) {
        self.default = `default`
    }

    /// Decodes a lossy sequence from the given `decoder`
    /// by ignoring invalid or corrupt element data.
    ///
    /// If the data format in decoder is invalid, or no valid element
    /// is found in decoder's container then provided default sequence
    /// is returned.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The lossy sequence decoded.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the encountered
    ///   stored value is not an unkeyed container.
    public func decode(from decoder: Decoder) throws -> S {
        var container = try decoder.unkeyedContainer()
        var result = Array<S.Element>()
        while !container.isAtEnd {
            let value: S.Element
            do { value = try container.decode(S.Element.self) } catch {
                _ = try? container.decode(AnyDecodable.self)
                continue
            }
            result.append(value)
        }
        return result.isEmpty ? self.default : S.init(result)
    }
}

@available(*, deprecated, message: "Use SequenceCoder from HelperCoders")
extension LossySequenceCoder: Sendable where S: Sendable {}

/// A sequence type that can be initialized from another sequence.
@_documentation(visibility: internal)
public protocol SequenceInitializable: Sequence {
    /// Creates a new instance of a sequence containing the elements of
    /// provided sequence.
    ///
    /// - Parameter sequence: The sequence of elements for the new sequence.
    init<S: Sequence>(_ sequence: S) where S.Element == Self.Element
}

extension Array: SequenceInitializable {}
extension Set: SequenceInitializable {}

/// Any value decodable type.
private struct AnyDecodable: Decodable {}
