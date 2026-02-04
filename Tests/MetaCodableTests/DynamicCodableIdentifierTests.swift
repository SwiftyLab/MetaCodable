import Foundation
import MetaCodable
import Testing

/// Tests for `DynamicCodableIdentifier` CodingKey conformance.
///
/// These tests verify the CodingKey protocol implementation for
/// DynamicCodableIdentifier, including integer and string initialization.
@Suite("Dynamic Codable Identifier Tests")
struct DynamicCodableIdentifierTests {
    
    // MARK: init(intValue:)
    
    @Suite("Init with Int values Tests")
    struct InitWithIntValuesTests {
        
        /// Tests that `init(intValue:)` always returns nil.
        ///
        /// DynamicCodableIdentifier uses string-based keys only,
        /// so integer initialization is not supported.
        @Test("Tests init int value returns nil", .tags(.coverage, .dynamicCoding))
        func initIntValueReturnsNil() {
            let identifier = DynamicCodableIdentifier<String>(intValue: 0)
            #expect(identifier == nil)
            
            let identifier2 = DynamicCodableIdentifier<String>(intValue: 42)
            #expect(identifier2 == nil)
            
            let identifier3 = DynamicCodableIdentifier<String>(intValue: -1)
            #expect(identifier3 == nil)
        }
        
        /// Tests that `intValue` property always returns nil.
        @Test("Tests int value property returns nil", .tags(.coverage, .dynamicCoding))
        func intValuePropertyReturnsNil() {
            let identifier: DynamicCodableIdentifier<String> = .one("test")
            #expect(identifier.intValue == nil)
            
            let multiIdentifier: DynamicCodableIdentifier<String> = .many(["a", "b"])
            #expect(multiIdentifier.intValue == nil)
        }
    }
    
    // MARK: init(stringValue:)
        
    @Suite("Init with String values Tests")
    struct InitWithStringValuesTests {
    /// Tests that `init(stringValue:)` creates a single identifier.
        @Test("Tests init string value creates single identifier", .tags(.coverage, .dynamicCoding, .optionals))
        func initStringValueCreatesSingleIdentifier() {
            let identifier = DynamicCodableIdentifier<String>(stringValue: "test")
            #expect(identifier != nil)
            #expect(identifier?.stringValue == "test")
        }
    }
    
    // MARK: stringValue
    
    @Suite("Returning String values Tests")
    struct ReturningStringValuesTests {
        
        /// Tests that `stringValue` returns the value for single identifier.
        @Test("Tests string value returns single value", .tags(.coverage, .dynamicCoding))
        func stringValueReturnsSingleValue() {
            let identifier: DynamicCodableIdentifier<String> = .one("myKey")
            #expect(identifier.stringValue == "myKey")
        }
        
        /// Tests that `stringValue` returns first value for multiple identifiers.
        @Test("Tests string value returns first value", .tags(.coverage, .dynamicCoding))
        func stringValueReturnsFirstValue() {
            let identifier: DynamicCodableIdentifier<String> = .many(["first", "second", "third"])
            #expect(identifier.stringValue == "first")
        }
        
        /// Tests that `stringValue` returns empty string for empty multiple identifiers.
        @Test("Tests string value returns empty for empty array", .tags(.coverage, .dynamicCoding))
        func stringValueReturnsEmptyForEmptyArray() {
            let identifier: DynamicCodableIdentifier<String> = .many([])
            #expect(identifier.stringValue == "")
        }
    }
    
    // MARK: Pattern Matching Tests
    
    @Suite("Pattern Matching Tests")
    struct PatternMatchingTests {
        
        /// Tests pattern matching with single identifier.
        @Test("Tests pattern matching single identifier", .tags(.coverage, .dynamicCoding, .optionals, .structs))
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
        @Test("Tests pattern matching multiple identifiers", .tags(.coverage, .dynamicCoding, .optionals, .structs))
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
}
