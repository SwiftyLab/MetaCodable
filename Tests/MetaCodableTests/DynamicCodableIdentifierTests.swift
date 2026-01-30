import Foundation
import MetaCodable
import Testing

/// Tests for `DynamicCodableIdentifier` CodingKey conformance.
///
/// These tests verify the CodingKey protocol implementation for
/// DynamicCodableIdentifier, including integer and string initialization.
@Suite("DynamicCodableIdentifier CodingKey Tests")
struct DynamicCodableIdentifierTests {
    
    // MARK: - init(intValue:) Tests
    
    /// Tests that `init(intValue:)` always returns nil.
    ///
    /// DynamicCodableIdentifier uses string-based keys only,
    /// so integer initialization is not supported.
    @Test("init(intValue:) returns nil")
    func initIntValueReturnsNil() {
        let identifier = DynamicCodableIdentifier<String>(intValue: 0)
        #expect(identifier == nil)
        
        let identifier2 = DynamicCodableIdentifier<String>(intValue: 42)
        #expect(identifier2 == nil)
        
        let identifier3 = DynamicCodableIdentifier<String>(intValue: -1)
        #expect(identifier3 == nil)
    }
    
    /// Tests that `intValue` property always returns nil.
    @Test("intValue property returns nil")
    func intValuePropertyReturnsNil() {
        let identifier: DynamicCodableIdentifier<String> = .one("test")
        #expect(identifier.intValue == nil)
        
        let multiIdentifier: DynamicCodableIdentifier<String> = .many(["a", "b"])
        #expect(multiIdentifier.intValue == nil)
    }
    
    // MARK: - init(stringValue:) Tests
    
    /// Tests that `init(stringValue:)` creates a single identifier.
    @Test("init(stringValue:) creates single identifier")
    func initStringValueCreatesSingleIdentifier() {
        let identifier = DynamicCodableIdentifier<String>(stringValue: "test")
        #expect(identifier != nil)
        #expect(identifier?.stringValue == "test")
    }
    
    // MARK: - stringValue Tests
    
    /// Tests that `stringValue` returns the value for single identifier.
    @Test("stringValue returns value for single identifier")
    func stringValueReturnsSingleValue() {
        let identifier: DynamicCodableIdentifier<String> = .one("myKey")
        #expect(identifier.stringValue == "myKey")
    }
    
    /// Tests that `stringValue` returns first value for multiple identifiers.
    @Test("stringValue returns first value for multiple identifiers")
    func stringValueReturnsFirstValue() {
        let identifier: DynamicCodableIdentifier<String> = .many(["first", "second", "third"])
        #expect(identifier.stringValue == "first")
    }
    
    /// Tests that `stringValue` returns empty string for empty multiple identifiers.
    @Test("stringValue returns empty string for empty array")
    func stringValueReturnsEmptyForEmptyArray() {
        let identifier: DynamicCodableIdentifier<String> = .many([])
        #expect(identifier.stringValue == "")
    }
    
    // MARK: - Pattern Matching Tests
    
    /// Tests pattern matching with single identifier.
    @Test("pattern matching works with single identifier")
    func patternMatchingSingleIdentifier() {
        let identifier: DynamicCodableIdentifier<String> = .one("type")
        
        struct TestKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init?(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }
        
        let key = TestKey(stringValue: "type")!
        #expect(identifier ~= key)
        
        let otherKey = TestKey(stringValue: "other")!
        #expect(!(identifier ~= otherKey))
    }
    
    /// Tests pattern matching with multiple identifiers.
    @Test("pattern matching works with multiple identifiers")
    func patternMatchingMultipleIdentifiers() {
        let identifier: DynamicCodableIdentifier<String> = .many(["type", "kind", "category"])
        
        struct TestKey: CodingKey {
            var stringValue: String
            var intValue: Int? { nil }
            init?(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }
        
        #expect(identifier ~= TestKey(stringValue: "type")!)
        #expect(identifier ~= TestKey(stringValue: "kind")!)
        #expect(identifier ~= TestKey(stringValue: "category")!)
        #expect(!(identifier ~= TestKey(stringValue: "other")!))
    }
}
