import Foundation
import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// base64 data.
///
/// This type can be used to decode/encode base64 data
/// string and convert to `Data` type.
public struct Base64Coder: HelperCoder {
    /// The options to use when decoding data.
    private let decodeOptions: Data.Base64DecodingOptions
    /// The options to use when encoding data.
    private let encodeOptions: Data.Base64EncodingOptions

    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// base64 data.
    ///
    /// - Parameters:
    ///   - decodeOptions: The options to use when decoding data.
    ///   - encodeOptions: The options to use when encoding data.
    public init(
        decodeOptions: Data.Base64DecodingOptions = [],
        encodeOptions: Data.Base64EncodingOptions = []
    ) {
        self.decodeOptions = decodeOptions
        self.encodeOptions = encodeOptions
    }

    /// Decodes base64 data with provided decoding options
    /// from the given `decoder`.
    ///
    /// The data is decoded from a base64 string representation.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The data decoded.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the decoded string
    ///   isn't a valid base64 representation.
    public func decode(from decoder: Decoder) throws -> Data {
        let base64Str = try String(from: decoder)
        guard let data = Data(base64Encoded: base64Str, options: decodeOptions)
        else {
            let errDesc = "Invalid base64 string \"\(base64Str)\""
            throw DecodingError.typeMismatch(
                Data.self,
                .init(codingPath: decoder.codingPath, debugDescription: errDesc)
            )
        }
        return data
    }

    /// Encodes base64 data with provided encoding options
    /// to the given `decoder`.
    ///
    /// The data is encoded as a base64 string representation.
    ///
    /// - Parameters:
    ///   - value: The data to encode.
    ///   - encoder: The encoder to write data to.
    public func encode(_ value: Data, to encoder: Encoder) throws {
        let base64Str = value.base64EncodedString(options: encodeOptions)
        try base64Str.encode(to: encoder)
    }
}
