import Foundation
import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Coded As Tests")
struct CodedAsTests {
    @Test("Reports error for @CodedAs misuse (CodedAsTests #2)", .tags(.codedAs, .errorHandling, .macroExpansion, .structs))
    func misuseOnGroupedVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAs("alt")
                let one, two, three: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one, two, three: String
                }
                """,
            diagnostics: [
                .multiBinding(line: 2, column: 5)
            ]
        )
    }

    @Test("Reports error for @CodedAs misuse (CodedAsTests #3)", .tags(.codedAs, .errorHandling, .macroExpansion, .structs))
    func misuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAs("alt")
                static let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    static let value: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @CodedAs misuse (CodedAsTests #4)", .tags(.codedAs, .errorHandling, .ignoreCoding, .macroExpansion, .structs))
    func misuseInCombinationWithIgnoreCodingMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAs("alt")
                @IgnoreCoding
                let one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String = "some"
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can't be used in combination with @IgnoreCoding",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used in combination with @CodedAs",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
            ]
        )
    }

    @Test("Reports error when @CodedAs is applied multiple times (CodedAsTests #1)", .tags(.codedAs, .errorHandling, .macroExpansion, .structs))
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAs("two")
                @CodedAs("three")
                let one: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Coded As - With Value")
    struct WithValue {
        @Codable
        struct SomeCodable {
            @CodedAs("key")
            let value: String
            @CodedAs("key1", "key2")
            let value1: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #2)", .tags(.codable, .codedAs, .decoding, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedAs("key")
                    let value: String
                    @CodedAs("key1", "key2")
                    let value1: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String
                        let value1: String
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let valueKeys = [CodingKeys.value, CodingKeys.key].filter {
                                container.allKeys.contains($0)
                            }
                            guard valueKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.value = try container.decode(String.self, forKey: valueKeys[0])
                            let value1Keys = [CodingKeys.value1, CodingKeys.key1, CodingKeys.key2].filter {
                                container.allKeys.contains($0)
                            }
                            guard value1Keys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.value1 = try container.decode(String.self, forKey: value1Keys[0])
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try container.encode(self.value1, forKey: CodingKeys.value1)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case key = "key"
                            case value = "value"
                            case key1 = "key1"
                            case key2 = "key2"
                            case value1 = "value1"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedAsTests #6)", .tags(.codedAs, .decoding, .encoding))
        func codedAsKeyMapping() throws {
            let original = SomeCodable(value: "test1", value1: "test2")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "test1")
            #expect(decoded.value1 == "test2")
        }

        @Test("Decodes from JSON successfully (CodedAsTests #8)", .tags(.codedAs, .decoding))
        func codedAsFromJSON() throws {
            let jsonStr = """
                {
                    "key": "mapped_value",
                    "key1": "multi_mapped_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "mapped_value")
            #expect(decoded.value1 == "multi_mapped_value")
        }

        @Test("Decodes from JSON successfully (CodedAsTests #9)", .tags(.codedAs, .decoding))
        func codedAsAlternativeKeys() throws {
            // Test with key2 instead of key1
            let jsonStr = """
                {
                    "key": "mapped_value",
                    "key2": "alternative_key_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "mapped_value")
            #expect(decoded.value1 == "alternative_key_value")
        }

        @Test("Encodes to JSON successfully (CodedAsTests #2)", .tags(.codedAs, .encoding, .optionals))
        func codedAsJSONStructure() throws {
            let original = SomeCodable(value: "test", value1: "test2")
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]

            // The actual behavior shows that encoding uses the original property names
            // while decoding can use the alternative keys
            #expect(json["value"] as? String == "test")
            #expect(json["value1"] as? String == "test2")
            // The mapped keys should not be present in encoding
            #expect(json["key"] == nil)
            #expect(json["key1"] == nil)
        }
    }

    @Suite("Coded As - With Any Codable Literal Enum")
    struct WithAnyCodableLiteralEnum {
        @Codable
        @CodedAt("type")
        enum Command {
            @CodedAs("load", 12, true, 3.14, 15..<20, (-0.8)...)
            case load(key: String)
            @CodedAs("store", 30, false, 7.15, 35...40, ..<(-1.5))
            case store(key: String, value: Int)
        }

        @Test("Generates macro expansion with @Codable for enum (CodedAsTests #4)", .tags(.codable, .codedAs, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .optionals))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                enum Command {
                    @CodedAs("load", 12, true, 3.14, 15..<20, (-0.8)...)
                    case load(key: String)
                    @CodedAs("store", 30, false, 7.15, 35...40, ..<(-1.5))
                    case store(key: String, value: Int)
                }
                """,
                expandedSource:
                    """
                    enum Command {
                        case load(key: String)
                        case store(key: String, value: Int)
                    }

                    extension Command: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                typeContainer = container
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer, let container = container {
                                let typeBool: Bool?
                                do {
                                    typeBool = try typeContainer.decodeIfPresent(Bool.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeBool = nil
                                }
                                if let typeBool = typeBool {
                                    switch typeBool {
                                    case true:
                                        let key: String
                                        let container = try decoder.container(keyedBy: CodingKeys.self)
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        self = .load(key: key)
                                        return
                                    case false:
                                        let key: String
                                        let value: Int
                                        let container = try decoder.container(keyedBy: CodingKeys.self)
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        value = try container.decode(Int.self, forKey: CodingKeys.value)
                                        self = .store(key: key, value: value)
                                        return
                                    }
                                }
                                let typeInt: Int?
                                do {
                                    typeInt = try typeContainer.decodeIfPresent(Int.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeInt = nil
                                }
                                if let typeInt = typeInt {
                                    switch typeInt {
                                    case 12, 15 ..< 20:
                                        let key: String
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        self = .load(key: key)
                                        return
                                    case 30, 35 ... 40:
                                        let key: String
                                        let value: Int
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        value = try container.decode(Int.self, forKey: CodingKeys.value)
                                        self = .store(key: key, value: value)
                                        return
                                    default:
                                        break
                                    }
                                }
                                let typeDouble: Double?
                                do {
                                    typeDouble = try typeContainer.decodeIfPresent(Double.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeDouble = nil
                                }
                                if let typeDouble = typeDouble {
                                    switch typeDouble {
                                    case 3.14, (-0.8)...:
                                        let key: String
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        self = .load(key: key)
                                        return
                                    case 7.15, ..<(-1.5):
                                        let key: String
                                        let value: Int
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        value = try container.decode(Int.self, forKey: CodingKeys.value)
                                        self = .store(key: key, value: value)
                                        return
                                    default:
                                        break
                                    }
                                }
                                let typeString: String?
                                do {
                                    typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeString = nil
                                }
                                if let typeString = typeString {
                                    switch typeString {
                                    case "load":
                                        let key: String
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        self = .load(key: key)
                                        return
                                    case "store":
                                        let key: String
                                        let value: Int
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        value = try container.decode(Int.self, forKey: CodingKeys.value)
                                        self = .store(key: key, value: value)
                                        return
                                    default:
                                        break
                                    }
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Command: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            switch self {
                            case .load(key: let key):
                                try typeContainer.encode("load", forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
                                try typeContainer.encode("store", forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                                try container.encode(value, forKey: CodingKeys.value)
                            }
                        }
                    }

                    extension Command {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                            case key = "key"
                            case value = "value"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedAsTests #7)", .tags(.codedAs, .decoding, .encoding))
        func enumMixedLiteralRoundtrip() throws {
            let loadCmd: Command = .load(key: "test_key")
            let encoded = try JSONEncoder().encode(loadCmd)
            let decoded = try JSONDecoder().decode(Command.self, from: encoded)

            if case .load(let key) = decoded {
                #expect(key == "test_key")
            } else {
                Issue.record("Expected .load case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #10)", .tags(.codedAs, .decoding))
        func enumStringTypeDecoding() throws {
            let jsonStr = """
                {
                    "type": "load",
                    "key": "string_type_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "string_type_key")
            } else {
                Issue.record("Expected .load case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #11)", .tags(.codedAs, .decoding))
        func enumIntegerTypeDecoding() throws {
            let jsonStr = """
                {
                    "type": 12,
                    "key": "integer_type_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "integer_type_key")
            } else {
                Issue.record("Expected .load case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #12)", .tags(.codedAs, .decoding))
        func enumBooleanTypeDecoding() throws {
            let jsonStr = """
                {
                    "type": true,
                    "key": "boolean_type_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "boolean_type_key")
            } else {
                Issue.record("Expected .load case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #13)", .tags(.codedAs, .decoding))
        func enumDoubleTypeDecoding() throws {
            let jsonStr = """
                {
                    "type": 3.14,
                    "key": "double_type_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "double_type_key")
            } else {
                Issue.record("Expected .load case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #14)", .tags(.codedAs, .decoding))
        func enumStoreWithIntegerType() throws {
            let jsonStr = """
                {
                    "type": 30,
                    "key": "store_key",
                    "value": 42
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "store_key")
                #expect(value == 42)
            } else {
                Issue.record("Expected .store case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #15)", .tags(.codedAs, .decoding))
        func enumStoreWithBooleanType() throws {
            let jsonStr = """
                {
                    "type": false,
                    "key": "store_key",
                    "value": 99
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "store_key")
                #expect(value == 99)
            } else {
                Issue.record("Expected .store case")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #16)", .tags(.codedAs, .decoding))
        func enumStoreWithDoubleType() throws {
            let jsonStr = """
                {
                    "type": -2.0,
                    "key": "store_key",
                    "value": 123
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "store_key")
                #expect(value == 123)
            } else {
                Issue.record("Expected .store case")
            }
        }

        @Test("Encodes to JSON successfully (CodedAsTests #3)", .tags(.codedAs, .encoding, .optionals))
        func enumEncodingStructure() throws {
            let storeCmd: Command = .store(key: "test", value: 100)
            let encoded = try JSONEncoder().encode(storeCmd)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]

            // Encoding always uses the first (string) value for the type
            #expect(json["type"] as? String == "store")
            #expect(json["key"] as? String == "test")
            #expect(json["value"] as? Int == 100)
        }

        @Test("Encodes to JSON successfully (CodedAsTests #4)", .tags(.codedAs, .encoding, .optionals))
        func enumLoadEncodingStructure() throws {
            let loadCmd: Command = .load(key: "load_test")
            let encoded = try JSONEncoder().encode(loadCmd)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]

            // Encoding always uses the first (string) value for the type
            #expect(json["type"] as? String == "load")
            #expect(json["key"] as? String == "load_test")
            #expect(json["value"] == nil)  // No value for load case
        }

        @Test("Decodes from JSON successfully (CodedAsTests #17)", .tags(.codedAs, .decoding))
        func enumInvalidTypeDecoding() throws {
            let jsonStr = """
                {
                    "type": "invalid",
                    "key": "test_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))

            #expect(throws: DecodingError.self) {
                let _ = try JSONDecoder().decode(Command.self, from: jsonData)
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #18)", .tags(.codedAs, .decoding))
        func enumMissingTypeDecoding() throws {
            let jsonStr = """
                {
                    "key": "test_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))

            #expect(throws: DecodingError.self) {
                let _ = try JSONDecoder().decode(Command.self, from: jsonData)
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #19)", .tags(.codedAs, .decoding))
        func enumIntegerRangeLoadCase() throws {
            // Test integer in range 15..<20 for load case
            let jsonStr = """
                {
                    "type": 17,
                    "key": "range_test_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "range_test_key")
            } else {
                Issue.record(
                    "Expected .load case for integer 17 in range 15..<20")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #20)", .tags(.codedAs, .decoding))
        func enumIntegerRangeStoreCase() throws {
            // Test integer in range 35...40 for store case
            let jsonStr = """
                {
                    "type": 38,
                    "key": "store_range_key",
                    "value": 200
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "store_range_key")
                #expect(value == 200)
            } else {
                Issue.record(
                    "Expected .store case for integer 38 in range 35...40")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #21)", .tags(.codedAs, .decoding))
        func enumIntegerRangeBoundaryValues() throws {
            // Test boundary values for ranges

            // Test 15 (not in 15..<20, should not match load case)
            let jsonStr15 = """
                {
                    "type": 15,
                    "key": "boundary_key"
                }
                """
            let jsonData15 = try #require(jsonStr15.data(using: .utf8))
            let decoded15 = try JSONDecoder().decode(
                Command.self, from: jsonData15)

            if case .load(let key) = decoded15 {
                #expect(key == "boundary_key")
            } else {
                Issue.record(
                    "Expected .load case for integer 15 in range 15..<20")
            }

            // Test 19 (in 15..<20, should match load case)
            let jsonStr19 = """
                {
                    "type": 19,
                    "key": "boundary_key"
                }
                """
            let jsonData19 = try #require(jsonStr19.data(using: .utf8))
            let decoded19 = try JSONDecoder().decode(
                Command.self, from: jsonData19)

            if case .load(let key) = decoded19 {
                #expect(key == "boundary_key")
            } else {
                Issue.record(
                    "Expected .load case for integer 19 in range 15..<20")
            }

            // Test 35 (in 35...40, should match store case)
            let jsonStr35 = """
                {
                    "type": 35,
                    "key": "boundary_key",
                    "value": 300
                }
                """
            let jsonData35 = try #require(jsonStr35.data(using: .utf8))
            let decoded35 = try JSONDecoder().decode(
                Command.self, from: jsonData35)

            if case .store(let key, let value) = decoded35 {
                #expect(key == "boundary_key")
                #expect(value == 300)
            } else {
                Issue.record(
                    "Expected .store case for integer 35 in range 35...40")
            }

            // Test 40 (in 35...40, should match store case)
            let jsonStr40 = """
                {
                    "type": 40,
                    "key": "boundary_key",
                    "value": 400
                }
                """
            let jsonData40 = try #require(jsonStr40.data(using: .utf8))
            let decoded40 = try JSONDecoder().decode(
                Command.self, from: jsonData40)

            if case .store(let key, let value) = decoded40 {
                #expect(key == "boundary_key")
                #expect(value == 400)
            } else {
                Issue.record(
                    "Expected .store case for integer 40 in range 35...40")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #22)", .tags(.codedAs, .decoding))
        func enumDoublePartialRangeLoadCase() throws {
            // Test double in partial range (-0.8)... for load case
            let jsonStr = """
                {
                    "type": 5.5,
                    "key": "partial_range_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "partial_range_key")
            } else {
                Issue.record(
                    "Expected .load case for double 5.5 in range (-0.8)...")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #23)", .tags(.codedAs, .decoding))
        func enumDoublePartialRangeStoreCase() throws {
            // Test double in partial range ..<(-1.5) for store case
            let jsonStr = """
                {
                    "type": -3.0,
                    "key": "partial_range_store_key",
                    "value": 500
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "partial_range_store_key")
                #expect(value == 500)
            } else {
                Issue.record(
                    "Expected .store case for double -3.0 in range ..<(-1.5)")
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #24)", .tags(.codedAs, .decoding))
        func enumDoubleRangeBoundaryValues() throws {
            // Test boundary values for double ranges

            // Test -0.8 (in (-0.8)..., should match load case)
            let jsonStrBoundary = """
                {
                    "type": -0.8,
                    "key": "double_boundary_key"
                }
                """
            let jsonDataBoundary = try #require(
                jsonStrBoundary.data(using: .utf8))
            let decodedBoundary = try JSONDecoder().decode(
                Command.self, from: jsonDataBoundary)

            if case .load(let key) = decodedBoundary {
                #expect(key == "double_boundary_key")
            } else {
                Issue.record(
                    "Expected .load case for double -0.8 in range (-0.8)...")
            }

            // Test -1.5 (not in ..<(-1.5), should not match store case)
            let jsonStrNotInRange = """
                {
                    "type": -1.5,
                    "key": "not_in_range_key",
                    "value": 600
                }
                """
            let jsonDataNotInRange = try #require(
                jsonStrNotInRange.data(using: .utf8))
            #expect(throws: DecodingError.self) {
                let _ = try JSONDecoder().decode(
                    Command.self, from: jsonDataNotInRange)
            }
        }

        @Test("Decodes from JSON successfully (CodedAsTests #25)", .tags(.codedAs, .decoding))
        func enumRangeValuesPriorityOverLiterals() throws {
            // Test that range values work alongside literal values
            // Integer 16 should match the range 15..<20 for load case, not the literal 12
            let jsonStr = """
                {
                    "type": 16,
                    "key": "priority_test_key"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .load(let key) = decoded {
                #expect(key == "priority_test_key")
            } else {
                Issue.record(
                    "Expected .load case for integer 16 matching range 15..<20")
            }
        }
    }

    @Suite("Coded As - With Helper And Value")
    struct WithHelperAndValue {
        @Codable
        struct SomeCodable {
            @CodedAs("key")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value: [String]
            @CodedAs("key1", "key2")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            let value1: [String]
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #3)", .tags(.codable, .codedAs, .codedBy, .decoding, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedAs("key")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value: [String]
                    @CodedAs("key1", "key2")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    let value1: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]
                        let value1: [String]
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let valueKeys = [CodingKeys.value, CodingKeys.key].filter {
                                container.allKeys.contains($0)
                            }
                            guard valueKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decode(from: container, forKey: valueKeys[0])
                            let value1Keys = [CodingKeys.value1, CodingKeys.key1, CodingKeys.key2].filter {
                                container.allKeys.contains($0)
                            }
                            guard value1Keys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.value1 = try SequenceCoder(output: [String].self, configuration: .lossy).decode(from: container, forKey: value1Keys[0])
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value, to: &container, atKey: CodingKeys.value)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value1, to: &container, atKey: CodingKeys.value1)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case key = "key"
                            case value = "value"
                            case key1 = "key1"
                            case key2 = "key2"
                            case value1 = "value1"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded As - Default")
    struct WithDefaultValue {
        @Codable
        struct SomeCodable {
            @CodedAs("key")
            @Default("some")
            let value: String
            @CodedAs("key1", "key2")
            @Default("some")
            let value1: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #4)", .tags(.codable, .codedAs, .default, .encoding, .enums, .macroExpansion, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedAs("key")
                    @Default("some")
                    let value: String
                    @CodedAs("key1", "key2")
                    @Default("some")
                    let value1: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String
                        let value1: String
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                do {
                                    let valueKeys = [CodingKeys.value, CodingKeys.key].filter {
                                        container.allKeys.contains($0)
                                    }
                                    guard valueKeys.count == 1 else {
                                        let context = DecodingError.Context(
                                            codingPath: container.codingPath,
                                            debugDescription: "Invalid number of keys found, expected one."
                                        )
                                        throw DecodingError.typeMismatch(Self.self, context)
                                    }
                                    self.value = try container.decodeIfPresent(String.self, forKey: valueKeys[0]) ?? "some"
                                } catch {
                                    self.value = "some"
                                }
                                do {
                                    let value1Keys = [CodingKeys.value1, CodingKeys.key1, CodingKeys.key2].filter {
                                        container.allKeys.contains($0)
                                    }
                                    guard value1Keys.count == 1 else {
                                        let context = DecodingError.Context(
                                            codingPath: container.codingPath,
                                            debugDescription: "Invalid number of keys found, expected one."
                                        )
                                        throw DecodingError.typeMismatch(Self.self, context)
                                    }
                                    self.value1 = try container.decodeIfPresent(String.self, forKey: value1Keys[0]) ?? "some"
                                } catch {
                                    self.value1 = "some"
                                }
                            } else {
                                self.value = "some"
                                self.value1 = "some"
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try container.encode(self.value1, forKey: CodingKeys.value1)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case key = "key"
                            case value = "value"
                            case key1 = "key1"
                            case key2 = "key2"
                            case value1 = "value1"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded As - With Helper And Default Value")
    struct WithHelperAndDefaultValue {
        @Codable
        struct SomeCodable {
            @CodedAs("key")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @Default(["some"])
            let value: [String]
            @CodedAs("key1", "key2")
            @CodedBy(
                SequenceCoder(output: [String].self, configuration: .lossy)
            )
            @Default(["some"])
            let value1: [String]
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #5)", .tags(.codable, .codedAs, .codedBy, .default, .encoding, .enums, .macroExpansion, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedAs("key")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @Default(["some"])
                    let value: [String]
                    @CodedAs("key1", "key2")
                    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
                    @Default(["some"])
                    let value1: [String]
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: [String]
                        let value1: [String]
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                do {
                                    let valueKeys = [CodingKeys.value, CodingKeys.key].filter {
                                        container.allKeys.contains($0)
                                    }
                                    guard valueKeys.count == 1 else {
                                        let context = DecodingError.Context(
                                            codingPath: container.codingPath,
                                            debugDescription: "Invalid number of keys found, expected one."
                                        )
                                        throw DecodingError.typeMismatch(Self.self, context)
                                    }
                                    self.value = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: container, forKey: valueKeys[0]) ?? ["some"]
                                } catch {
                                    self.value = ["some"]
                                }
                                do {
                                    let value1Keys = [CodingKeys.value1, CodingKeys.key1, CodingKeys.key2].filter {
                                        container.allKeys.contains($0)
                                    }
                                    guard value1Keys.count == 1 else {
                                        let context = DecodingError.Context(
                                            codingPath: container.codingPath,
                                            debugDescription: "Invalid number of keys found, expected one."
                                        )
                                        throw DecodingError.typeMismatch(Self.self, context)
                                    }
                                    self.value1 = try SequenceCoder(output: [String].self, configuration: .lossy).decodeIfPresent(from: container, forKey: value1Keys[0]) ?? ["some"]
                                } catch {
                                    self.value1 = ["some"]
                                }
                            } else {
                                self.value = ["some"]
                                self.value1 = ["some"]
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value, to: &container, atKey: CodingKeys.value)
                            try SequenceCoder(output: [String].self, configuration: .lossy).encode(self.value1, to: &container, atKey: CodingKeys.value1)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case key = "key"
                            case value = "value"
                            case key1 = "key1"
                            case key2 = "key2"
                            case value1 = "value1"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded As - Coding Key Case Name Collision Handling")
    struct CodingKeyCaseNameCollisionHandling {
        @Codable
        struct TestCodable {
            @CodedAs("fooBar", "foo_bar")
            var fooBar: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #6)", .tags(.codable, .codedAs, .decoding, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct TestCodable {
                    @CodedAs("fooBar", "foo_bar")
                    var fooBar: String
                }
                """,
                expandedSource:
                    """
                    struct TestCodable {
                        var fooBar: String
                    }

                    extension TestCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let fooBarKeys = [CodingKeys.fooBar, CodingKeys.__macro_local_6fooBarfMu0_].filter {
                                container.allKeys.contains($0)
                            }
                            guard fooBarKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.fooBar = try container.decode(String.self, forKey: fooBarKeys[0])
                        }
                    }

                    extension TestCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.fooBar, forKey: CodingKeys.fooBar)
                        }
                    }

                    extension TestCodable {
                        enum CodingKeys: String, CodingKey {
                            case fooBar = "fooBar"
                            case __macro_local_6fooBarfMu0_ = "foo_bar"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded As - Coding Key Case Name Collision Handling With Duplicate Aliases")
    struct CodingKeyCaseNameCollisionHandlingWithDuplicateAliases {
        @Codable
        struct TestCodable {
            @CodedAs("fooBar", "foo_bar", "foo_bar")
            var fooBar: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAsTests #7)", .tags(.codable, .codedAs, .decoding, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct TestCodable {
                    @CodedAs("fooBar", "foo_bar", "foo_bar")
                    var fooBar: String
                }
                """,
                expandedSource:
                    """
                    struct TestCodable {
                        var fooBar: String
                    }

                    extension TestCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let fooBarKeys = [CodingKeys.fooBar, CodingKeys.__macro_local_6fooBarfMu0_].filter {
                                container.allKeys.contains($0)
                            }
                            guard fooBarKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            self.fooBar = try container.decode(String.self, forKey: fooBarKeys[0])
                        }
                    }

                    extension TestCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.fooBar, forKey: CodingKeys.fooBar)
                        }
                    }

                    extension TestCodable {
                        enum CodingKeys: String, CodingKey {
                            case fooBar = "fooBar"
                            case __macro_local_6fooBarfMu0_ = "foo_bar"
                        }
                    }
                    """
            )
        }
    }
}
