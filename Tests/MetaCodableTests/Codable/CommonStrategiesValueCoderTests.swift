import Foundation
import HelperCoders
import MetaCodable
import Testing

// Test for @Codable(commonStrategies: [.codedBy(.valueCoder())])
struct CommonStrategiesValueCoderTests {
    @Codable(commonStrategies: [.codedBy(.valueCoder())])
    struct Model {
        let bool: Bool
        let int: Int
        let double: Double
        let string: String
    }

    @Test
    func testParsing() throws {
        let json = """
            {
                "bool": "true",
                "int": "42",
                "double": "3.1416",
                "string": 5265762156
            }
            """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let model = try decoder.decode(Model.self, from: jsonData)

        #expect(model.bool)
        #expect(model.int == 42)
        #expect(model.double == 3.1416)
        #expect(model.string == "5265762156")

        // Test that encoding works too
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(model)
        let reDecoded = try decoder.decode(Model.self, from: encoded)
        #expect(reDecoded.bool)
        #expect(reDecoded.int == 42)
        #expect(reDecoded.double == 3.1416)
        #expect(reDecoded.string == "5265762156")
    }

    @Test
    func expansion() throws {
        assertMacroExpansion(
            """
            @Codable(commonStrategies: [.codedBy(.valueCoder())])
            struct Model {
                let bool: Bool
                let int: Int
                let double: Double
                let string: String
            }
            """,
            expandedSource:
                """
                struct Model {
                    let bool: Bool
                    let int: Int
                    let double: Double
                    let string: String
                }

                extension Model: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.bool = try ValueCoder<Bool>().decode(from: container, forKey: CodingKeys.bool)
                        self.int = try ValueCoder<Int>().decode(from: container, forKey: CodingKeys.int)
                        self.double = try ValueCoder<Double>().decode(from: container, forKey: CodingKeys.double)
                        self.string = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.string)
                    }
                }

                extension Model: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try ValueCoder<Bool>().encode(self.bool, to: &container, atKey: CodingKeys.bool)
                        try ValueCoder<Int>().encode(self.int, to: &container, atKey: CodingKeys.int)
                        try ValueCoder<Double>().encode(self.double, to: &container, atKey: CodingKeys.double)
                        try ValueCoder<String>().encode(self.string, to: &container, atKey: CodingKeys.string)
                    }
                }

                extension Model {
                    enum CodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "int"
                        case double = "double"
                        case string = "string"
                    }
                }
                """
        )
    }

    // Test 1: Properties that don't conform to ValueCodingStrategy
    struct NonConformingTypes {
        @Codable(commonStrategies: [.codedBy(.valueCoder())])
        struct Model {
            // Should use the built-in ValueCoder for Int
            let number: Int
            // URL does not conform to ValueCodingStrategy, so should be encoded/decoded normally
            let url: URL
            // UUID conforms to Codable but not to ValueCodingStrategy, so should be encoded/decoded normally
            let identifier: UUID
        }

        @Test
        func testNonConformingTypes() throws {
            let json = """
                {
                    "number": "42",
                    "url": "https://example.com",
                    "identifier": "123e4567-e89b-12d3-a456-426614174000"
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let model = try decoder.decode(Model.self, from: jsonData)

            #expect(model.number == 42)
            #expect(model.url == URL(string: "https://example.com"))
            #expect(
                model.identifier
                    == UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")
            )

            // Test that encoding works too
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try encoder.encode(model)
            let reDecoded = try decoder.decode(Model.self, from: encoded)

            #expect(reDecoded.number == 42)
            #expect(reDecoded.url == URL(string: "https://example.com"))
            #expect(
                reDecoded.identifier
                    == UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")
            )
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable(commonStrategies: [.codedBy(.valueCoder())])
                struct Model {
                    let number: Int
                    let url: URL
                    let identifier: UUID
                }
                """,
                expandedSource:
                    """
                    struct Model {
                        let number: Int
                        let url: URL
                        let identifier: UUID
                    }

                    extension Model: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.number = try ValueCoder<Int>().decode(from: container, forKey: CodingKeys.number)
                            self.url = try container.decode(URL.self, forKey: CodingKeys.url)
                            self.identifier = try container.decode(UUID.self, forKey: CodingKeys.identifier)
                        }
                    }

                    extension Model: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try ValueCoder<Int>().encode(self.number, to: &container, atKey: CodingKeys.number)
                            try container.encode(self.url, forKey: CodingKeys.url)
                            try container.encode(self.identifier, forKey: CodingKeys.identifier)
                        }
                    }

                    extension Model {
                        enum CodingKeys: String, CodingKey {
                            case number = "number"
                            case url = "url"
                            case identifier = "identifier"
                        }
                    }
                    """
            )
        }
    }

    // Test 2: Custom types conforming to ValueCodingStrategy
    struct CustomStrategies {
        @Codable(commonStrategies: [.codedBy(.valueCoder([CGFloat.self]))])
        struct Model {
            // Should use standard String
            let text: String
            // Should use CGFloat
            let number: CGFloat
            // Should use standard String
            let plainText: String
        }

        @Test
        func testCustomStrategies() throws {
            let json = """
                {
                    "text": "hello",
                    "number": 21,
                    "plainText": "unchanged"
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let model = try decoder.decode(Model.self, from: jsonData)

            #expect(model.text == "hello")
            #expect(model.number == 21)
            #expect(model.plainText == "unchanged")

            // Test encoding
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try String(
                data: encoder.encode(model), encoding: .utf8
            )

            #expect(
                encoded
                    == #"{"number":21,"plainText":"unchanged","text":"hello"}"#
            )
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable(commonStrategies: [.codedBy(.valueCoder([CGFloat.self]))])
                struct Model {
                    let text: String
                    let number: CGFloat
                    let plainText: String
                }
                """,
                expandedSource:
                    """
                    struct Model {
                        let text: String
                        let number: CGFloat
                        let plainText: String
                    }

                    extension Model: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.text = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.text)
                            self.number = try ValueCoder<CGFloat>().decode(from: container, forKey: CodingKeys.number)
                            self.plainText = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.plainText)
                        }
                    }

                    extension Model: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try ValueCoder<String>().encode(self.text, to: &container, atKey: CodingKeys.text)
                            try ValueCoder<CGFloat>().encode(self.number, to: &container, atKey: CodingKeys.number)
                            try ValueCoder<String>().encode(self.plainText, to: &container, atKey: CodingKeys.plainText)
                        }
                    }

                    extension Model {
                        enum CodingKeys: String, CodingKey {
                            case text = "text"
                            case number = "number"
                            case plainText = "plainText"
                        }
                    }
                    """
            )
        }
    }

    // Test 3: Empty commonStrategies array
    struct EmptyStrategies {
        @Codable(commonStrategies: [])
        struct Model {
            let bool: Bool
            let int: Int
            let double: Double
            let string: String
        }

        @Test
        func testEmptyStrategies() throws {
            let json = """
                {
                    "bool": true,
                    "int": 42,
                    "double": 3.14,
                    "string": "test"
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let model = try decoder.decode(Model.self, from: jsonData)

            #expect(model.bool == true)
            #expect(model.int == 42)
            #expect(model.double == 3.14)
            #expect(model.string == "test")

            // Test that encoding works too
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try String(
                data: encoder.encode(model), encoding: .utf8
            )
            #expect(
                encoded
                    == #"{"bool":true,"double":3.14,"int":42,"string":"test"}"#
            )
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable(commonStrategies: [])
                struct Model {
                    let bool: Bool
                    let int: Int
                    let double: Double
                    let string: String
                }
                """,
                expandedSource:
                    """
                    struct Model {
                        let bool: Bool
                        let int: Int
                        let double: Double
                        let string: String
                    }

                    extension Model: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.bool = try container.decode(Bool.self, forKey: CodingKeys.bool)
                            self.int = try container.decode(Int.self, forKey: CodingKeys.int)
                            self.double = try container.decode(Double.self, forKey: CodingKeys.double)
                            self.string = try container.decode(String.self, forKey: CodingKeys.string)
                        }
                    }

                    extension Model: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.bool, forKey: CodingKeys.bool)
                            try container.encode(self.int, forKey: CodingKeys.int)
                            try container.encode(self.double, forKey: CodingKeys.double)
                            try container.encode(self.string, forKey: CodingKeys.string)
                        }
                    }

                    extension Model {
                        enum CodingKeys: String, CodingKey {
                            case bool = "bool"
                            case int = "int"
                            case double = "double"
                            case string = "string"
                        }
                    }
                    """
            )
        }
    }
}

extension CGFloat: ValueCodingStrategy {
    public static func decode(from decoder: Decoder) throws -> CGFloat {
        let value = try Double(from: decoder)
        return CGFloat(value)
    }

    public static func encode(_ value: CGFloat, to encoder: Encoder) throws {
        try Double(value).encode(to: encoder)
    }
}
