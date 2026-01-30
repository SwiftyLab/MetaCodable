import Foundation
import MetaCodable
import Testing

/// Tests for `HelperCoder` protocol default implementations.
///
/// These tests verify the optional encoding/decoding paths that have
/// default implementations in the `HelperCoder` protocol extension.
@Suite("Helper Coder Tests")
struct HelperCoderTests {
    
    /// A simple helper coder for testing that wraps String values.
    struct StringWrapperCoder: HelperCoder {
        func decode(from decoder: Decoder) throws -> String {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            return "wrapped:\(value)"
        }
    }
    
    /// A helper coder for non-Encodable types to test the default encode path.
    struct NonEncodableValue {
        let value: Int
    }
    
    struct NonEncodableCoder: HelperCoder {
        func decode(from decoder: Decoder) throws -> NonEncodableValue {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(Int.self)
            return NonEncodableValue(value: value)
        }
    }
    
    // MARK: - decodeIfPresent Tests
    
    /// Tests that `decodeIfPresent` returns a value when valid data is present.
    @Test("Decodes struct from JSON successfully (HelperCoderTests #2)", .tags(.decoding, .enums, .helperCoders, .optionals, .structs))
    func decodeIfPresentWithValidData() throws {
        let json = #"{"value": "test"}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        struct Container: Decodable {
            let value: String
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                self.value = try coder.decodeIfPresent(
                    from: container,
                    forKey: .value
                ) ?? "default"
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let result = try decoder.decode(Container.self, from: data)
        #expect(result.value == "wrapped:test")
    }
    
    /// Tests that `decodeIfPresent` returns nil when data is null.
    @Test("Decodes struct from JSON successfully (HelperCoderTests #3)", .tags(.decoding, .enums, .helperCoders, .optionals, .structs))
    func decodeIfPresentWithNullData() throws {
        let json = #"{"value": null}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        struct Container: Decodable {
            let value: String?
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                self.value = try coder.decodeIfPresent(
                    from: container,
                    forKey: .value
                )
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let result = try decoder.decode(Container.self, from: data)
        #expect(result.value == nil)
    }
    
    /// Tests that `decodeIfPresent` returns nil when key is missing.
    @Test("Decodes struct from JSON successfully (HelperCoderTests #4)", .tags(.decoding, .enums, .helperCoders, .optionals, .structs))
    func decodeIfPresentWithMissingKey() throws {
        let json = #"{}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        struct Container: Decodable {
            let value: String?
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                self.value = try coder.decodeIfPresent(
                    from: container,
                    forKey: .value
                )
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let result = try decoder.decode(Container.self, from: data)
        #expect(result.value == nil)
    }
    
    // MARK: - encode Tests
    
    /// Tests that `encode` works for Encodable types.
    @Test("Encodes struct to JSON successfully (HelperCoderTests #2)", .tags(.encoding, .enums, .helperCoders, .structs))
    func encodeEncodableType() throws {
        struct Container: Encodable {
            let value: String
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                try coder.encode(value, to: &container, atKey: .value)
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let container = Container(value: "test")
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("test"))
    }
    
    /// Tests that `encode` does nothing for non-Encodable types (default implementation).
    @Test("Encodes struct to JSON successfully (HelperCoderTests #3)", .tags(.encoding, .enums, .helperCoders, .structs))
    func encodeNonEncodableType() throws {
        struct Container: Encodable {
            let nonEncodable: NonEncodableValue
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let coder = NonEncodableCoder()
                // This should not throw, just do nothing
                try coder.encode(nonEncodable, to: &container, atKey: .value)
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let container = Container(nonEncodable: NonEncodableValue(value: 42))
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        let json = String(data: data, encoding: .utf8)!
        
        // The non-encodable value should not appear in the output
        #expect(!json.contains("42"))
    }
    
    // MARK: - encodeIfPresent Tests
    
    /// Tests that `encodeIfPresent` encodes when value is present.
    @Test("Encodes struct to JSON successfully (HelperCoderTests #4)", .tags(.encoding, .enums, .helperCoders, .optionals, .structs))
    func encodeIfPresentWithValue() throws {
        struct Container: Encodable {
            let value: String?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                try coder.encodeIfPresent(value, to: &container, atKey: .value)
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let container = Container(value: "test")
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("test"))
    }
    
    /// Tests that `encodeIfPresent` skips encoding when value is nil.
    @Test("Encodes struct to JSON successfully (HelperCoderTests #5)", .tags(.encoding, .enums, .helperCoders, .optionals, .structs))
    func encodeIfPresentWithNil() throws {
        struct Container: Encodable {
            let value: String?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let coder = StringWrapperCoder()
                try coder.encodeIfPresent(value, to: &container, atKey: .value)
            }
            
            enum CodingKeys: String, CodingKey {
                case value
            }
        }
        
        let container = Container(value: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        let json = String(data: data, encoding: .utf8)!
        
        // Should be empty object since nil values are skipped
        #expect(json == "{}")
    }
}
