import Foundation
import MetaCodable

/// A ``DateCoder`` that helps decoding/encoding
/// **ISO 8601** formatted date representation.
///
/// This type can be used to decode/encode dates
/// represented in **ISO 8601** text format.
public typealias ISO8601DateCoder = DateCoder<ISO8601DateFormatter>

/// An `HelperCoder` that helps decoding/encoding
/// formatted date representation.
///
/// This type can be used to decode/encode dates
/// represented in text format.
public struct DateCoder<Formatter: DateFormatConverter>: HelperCoder {
    /// The formatter to use for text format conversion.
    @usableFromInline
    internal let formatter: Formatter

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// formatted date representation.
    ///
    /// Created instance can be used to decode/encode dates
    /// represented in text format.
    ///
    /// - Parameter formatter: The date formatter to use.
    public init(formatter: Formatter) {
        self.formatter = formatter
    }

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// **ISO 8601** formatted date representation.
    ///
    /// Created instance can be used to decode/encode dates
    /// represented in **ISO 8601** format.
    public init() where Formatter == ISO8601DateFormatter {
        self.formatter = Formatter()
    }

    /// Decodes formatted date representation from the given `decoder`.
    ///
    /// The decoded text data is parsed by provided formatter
    /// and converted to date.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The date decoded.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the decoded text
    ///   can't be converted to date by the formatter.
    public func decode(from decoder: Decoder) throws -> Date {
        let strValue = try String(from: decoder)

        guard let value = formatter.date(from: strValue) else {
            throw DecodingError.valueNotFound(
                Date.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: """
                        "\(strValue)" could not convert to Date by \(formatter)
                        """
                )
            )
        }
        return value
    }

    /// Encodes formatted date representation to the given `encoder`.
    ///
    /// Converts date to text by the provided formatter
    /// and encodes into encoder.
    ///
    /// - Parameters:
    ///   - value: The date to encode.
    ///   - encoder: The encoder to write data to.
    @inlinable
    public func encode(_ value: Date, to encoder: Encoder) throws {
        try formatter.string(from: value).encode(to: encoder)
    }
}

/// A formatter that converts between dates
/// and their textual representations.
///
/// This type can be used to parse date from
/// text representation and convert date to
/// text representation.
public protocol DateFormatConverter {
    /// Converts date into textual representation.
    ///
    /// Returns a string representation of a specified
    /// date that the system formats using the receiver’s
    /// current settings.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string representation of date.
    func string(from date: Date) -> String
    /// Parses date from provided text representation.
    ///
    /// Returns a date representation of a specified
    /// string that the system interprets using the
    /// receiver’s current settings.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: A date representation of string.
    ///   If can’t parse the string, returns `nil`.
    func date(from string: String) -> Date?
}

extension DateFormatter: DateFormatConverter {}
extension ISO8601DateFormatter: DateFormatConverter {}
