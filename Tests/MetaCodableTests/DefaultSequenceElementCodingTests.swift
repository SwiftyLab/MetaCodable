import Foundation
import MetaCodable
import Testing

@testable import HelperCoders

/// Tests for `DefaultSequenceElementCoding` helper coder.
///
/// These tests verify the optional encoding/decoding paths for the default
/// sequence element coding implementation used in sequence coders.
@Suite("Default Sequence Element Coding Tests")
struct DefaultSequenceElementCodingTests {
    
    /// Wrapper for decoding tests with keyed container.
    struct DecodingWrapper: Decodable {
        let value: String?
        
        enum CodingKeys: String, CodingKey {
            case value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let coder = DefaultSequenceElementCoding<String>()
            self.value = try coder.decodeIfPresent(from: container, forKey: .value)
        }
    }
    
    /// Wrapper for encoding tests with keyed container.
    struct EncodingWrapper: Encodable {
        let value: String?
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let coder = DefaultSequenceElementCoding<String>()
            try coder.encodeIfPresent(value, to: &container, atKey: .value)
        }
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
    
    // MARK: - decodeIfPresent(from:) Tests
    
    /// Tests that `decodeIfPresent(from:)` returns value from single value container.
    @Test("decodeIfPresent from decoder returns value when present")
    func decodeIfPresentFromDecoderReturnsValue() throws {
        let json = #""test""#
        let data = json.data(using: .utf8)!
        
        struct SingleValueWrapper: Decodable {
            let value: String?
            
            init(from decoder: Decoder) throws {
                let coder = DefaultSequenceElementCoding<String>()
                self.value = try coder.decodeIfPresent(from: decoder)
            }
        }
        
        let result = try JSONDecoder().decode(SingleValueWrapper.self, from: data)
        #expect(result.value == "test")
    }
    
    /// Tests that `decodeIfPresent(from:)` returns nil for null.
    @Test("decodeIfPresent from decoder returns nil for null")
    func decodeIfPresentFromDecoderReturnsNilForNull() throws {
        let json = #"null"#
        let data = json.data(using: .utf8)!
        
        struct SingleValueWrapper: Decodable {
            let value: String?
            
            init(from decoder: Decoder) throws {
                let coder = DefaultSequenceElementCoding<String>()
                self.value = try coder.decodeIfPresent(from: decoder)
            }
        }
        
        let result = try JSONDecoder().decode(SingleValueWrapper.self, from: data)
        #expect(result.value == nil)
    }
    
    // MARK: - decodeIfPresent(from:forKey:) Tests
    
    /// Tests that `decodeIfPresent(from:forKey:)` returns value when present.
    @Test("decodeIfPresent from keyed container returns value")
    func decodeIfPresentFromKeyedContainerReturnsValue() throws {
        let json = #"{"value": "test"}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == "test")
    }
    
    /// Tests that `decodeIfPresent(from:forKey:)` returns nil for null.
    @Test("decodeIfPresent from keyed container returns nil for null")
    func decodeIfPresentFromKeyedContainerReturnsNilForNull() throws {
        let json = #"{"value": null}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == nil)
    }
    
    /// Tests that `decodeIfPresent(from:forKey:)` returns nil for missing key.
    @Test("decodeIfPresent from keyed container returns nil for missing key")
    func decodeIfPresentFromKeyedContainerReturnsNilForMissingKey() throws {
        let json = #"{}"#
        let data = json.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(DecodingWrapper.self, from: data)
        #expect(result.value == nil)
    }
    
    // MARK: - encodeIfPresent(_:to:) Tests
    
    /// Tests that `encodeIfPresent(_:to:)` encodes value when present.
    @Test("encodeIfPresent to encoder encodes value when present")
    func encodeIfPresentToEncoderEncodesValue() throws {
        struct SingleValueWrapper: Encodable {
            let value: String?
            
            func encode(to encoder: Encoder) throws {
                let coder = DefaultSequenceElementCoding<String>()
                try coder.encodeIfPresent(value, to: encoder)
            }
        }
        
        let wrapper = SingleValueWrapper(value: "test")
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json == #""test""#)
    }
    
    /// Tests that `encodeIfPresent(_:to:)` encodes null for nil.
    @Test("encodeIfPresent to encoder encodes null for nil")
    func encodeIfPresentToEncoderEncodesNullForNil() throws {
        struct SingleValueWrapper: Encodable {
            let value: String?
            
            func encode(to encoder: Encoder) throws {
                let coder = DefaultSequenceElementCoding<String>()
                try coder.encodeIfPresent(value, to: encoder)
            }
        }
        
        let wrapper = SingleValueWrapper(value: nil)
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json == "null")
    }
    
    // MARK: - encodeIfPresent(_:to:atKey:) Tests
    
    /// Tests that `encodeIfPresent(_:to:atKey:)` encodes value when present.
    @Test("encodeIfPresent to keyed container encodes value when present")
    func encodeIfPresentToKeyedContainerEncodesValue() throws {
        let wrapper = EncodingWrapper(value: "test")
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("test"))
    }
    
    /// Tests that `encodeIfPresent(_:to:atKey:)` skips encoding for nil.
    @Test("encodeIfPresent to keyed container skips encoding for nil")
    func encodeIfPresentToKeyedContainerSkipsNil() throws {
        let wrapper = EncodingWrapper(value: nil)
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json == "{}")
    }
}
