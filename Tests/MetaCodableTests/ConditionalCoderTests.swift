import Foundation
import HelperCoders
import MetaCodable
import Testing

/// Tests for `ConditionalCoder` helper coder.
///
/// These tests verify the conditional encoding/decoding paths where
/// separate coders are used for decoding and encoding operations.
@Suite("Conditional Coder Tests")
struct ConditionalCoderTests {
    
    /// A decoder-only coder that prefixes decoded strings.
    struct PrefixDecoder: HelperCoder {
        let prefix: String
        
        func decode(from decoder: Decoder) throws -> String {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            return "\(prefix):\(value)"
        }
    }
    
    /// An encoder-only coder that suffixes encoded strings.
    struct SuffixEncoder: HelperCoder {
        let suffix: String
        
        func decode(from decoder: Decoder) throws -> String {
            let container = try decoder.singleValueContainer()
            return try container.decode(String.self)
        }
        
        func encode(_ value: String, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode("\(value):\(suffix)")
        }
    }
    
    /// Wrapper for decoding tests.
    struct DecodingWrapper: Decodable {
        let value: String?
        let coder: ConditionalCoder<PrefixDecoder, SuffixEncoder>
        
        enum CodingKeys: String, CodingKey {
            case value
        }
        
        init(from decoder: Decoder) throws {
            self.coder = ConditionalCoder(
                decoder: PrefixDecoder(prefix: "decoded"),
                encoder: SuffixEncoder(suffix: "encoded")
            )
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try coder.decodeIfPresent(
                from: container,
                forKey: .value
            )
        }
    }
    
    /// Wrapper for encoding tests.
    struct EncodingWrapper: Encodable {
        let value: String?
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let coder = ConditionalCoder(
                decoder: PrefixDecoder(prefix: "decoded"),
                encoder: SuffixEncoder(suffix: "encoded")
            )
            try coder.encodeIfPresent(value, to: &container, atKey: .value)
        }
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
    
    // MARK: - decodeIfPresent Tests
    
    /// Tests that `decodeIfPresent` uses the decoder coder and returns value.
    @Test("Decodes from JSON successfully (ConditionalCoderTests #34)", .tags(.conditionalCoder, .decoding))
    func decodeIfPresentReturnsValue() throws {
        let json = #"{"value": "test"}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == "decoded:test")
    }
    
    /// Tests that `decodeIfPresent` returns nil when value is null.
    @Test("Decodes from JSON successfully (ConditionalCoderTests #35)", .tags(.conditionalCoder, .decoding))
    func decodeIfPresentReturnsNilForNull() throws {
        let json = #"{"value": null}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == nil)
    }
    
    /// Tests that `decodeIfPresent` returns nil when key is missing.
    @Test("Decodes from JSON successfully (ConditionalCoderTests #36)", .tags(.conditionalCoder, .decoding))
    func decodeIfPresentReturnsNilForMissingKey() throws {
        let json = #"{}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == nil)
    }
    
    // MARK: - encodeIfPresent Tests
    
    /// Tests that `encodeIfPresent` uses the encoder coder when value is present.
    @Test("Encodes to JSON successfully (ConditionalCoderTests #7)", .tags(.conditionalCoder, .encoding))
    func encodeIfPresentEncodesValue() throws {
        let wrapper = EncodingWrapper(value: "test")
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("test:encoded"))
    }
    
    /// Tests that `encodeIfPresent` skips encoding when value is nil.
    @Test("Encodes to JSON successfully (ConditionalCoderTests #8)", .tags(.conditionalCoder, .encoding))
    func encodeIfPresentSkipsNil() throws {
        let wrapper = EncodingWrapper(value: nil)
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json == "{}")
    }
}
