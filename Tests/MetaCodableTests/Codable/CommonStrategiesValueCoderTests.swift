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
        let optBool: Bool?
        let optInt: Int?
        let optDouble: Double?
        let optString: String?
        let impBool: Bool!
        let impInt: Int!
        let impDouble: Double!
        let impString: String!
        let optGenBool: Bool?
        let optGenInt: Int?
        let optGenDouble: Double?
        let optGenString: String?
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
                let optBool: Bool?
                let optInt: Int?
                let optDouble: Double?
                let optString: String?
                let impBool: Bool!
                let impInt: Int!
                let impDouble: Double!
                let impString: String!
                let optGenBool: Optional<Bool>
                let optGenInt: Optional<Int>
                let optGenDouble: Optional<Double>
                let optGenString: Optional<String>
            }
            """,
            expandedSource:
                """
                struct Model {
                    let bool: Bool
                    let int: Int
                    let double: Double
                    let string: String
                    let optBool: Bool?
                    let optInt: Int?
                    let optDouble: Double?
                    let optString: String?
                    let impBool: Bool!
                    let impInt: Int!
                    let impDouble: Double!
                    let impString: String!
                    let optGenBool: Optional<Bool>
                    let optGenInt: Optional<Int>
                    let optGenDouble: Optional<Double>
                    let optGenString: Optional<String>
                }

                extension Model: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.bool = try ValueCoder<Bool>().decode(from: container, forKey: CodingKeys.bool)
                        self.int = try ValueCoder<Int>().decode(from: container, forKey: CodingKeys.int)
                        self.double = try ValueCoder<Double>().decode(from: container, forKey: CodingKeys.double)
                        self.string = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.string)
                        self.optBool = try ValueCoder<Bool>().decodeIfPresent(from: container, forKey: CodingKeys.optBool)
                        self.optInt = try ValueCoder<Int>().decodeIfPresent(from: container, forKey: CodingKeys.optInt)
                        self.optDouble = try ValueCoder<Double>().decodeIfPresent(from: container, forKey: CodingKeys.optDouble)
                        self.optString = try ValueCoder<String>().decodeIfPresent(from: container, forKey: CodingKeys.optString)
                        self.impBool = try ValueCoder<Bool>().decodeIfPresent(from: container, forKey: CodingKeys.impBool)
                        self.impInt = try ValueCoder<Int>().decodeIfPresent(from: container, forKey: CodingKeys.impInt)
                        self.impDouble = try ValueCoder<Double>().decodeIfPresent(from: container, forKey: CodingKeys.impDouble)
                        self.impString = try ValueCoder<String>().decodeIfPresent(from: container, forKey: CodingKeys.impString)
                        self.optGenBool = try ValueCoder<Bool>().decodeIfPresent(from: container, forKey: CodingKeys.optGenBool)
                        self.optGenInt = try ValueCoder<Int>().decodeIfPresent(from: container, forKey: CodingKeys.optGenInt)
                        self.optGenDouble = try ValueCoder<Double>().decodeIfPresent(from: container, forKey: CodingKeys.optGenDouble)
                        self.optGenString = try ValueCoder<String>().decodeIfPresent(from: container, forKey: CodingKeys.optGenString)
                    }
                }

                extension Model: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try ValueCoder<Bool>().encode(self.bool, to: &container, atKey: CodingKeys.bool)
                        try ValueCoder<Int>().encode(self.int, to: &container, atKey: CodingKeys.int)
                        try ValueCoder<Double>().encode(self.double, to: &container, atKey: CodingKeys.double)
                        try ValueCoder<String>().encode(self.string, to: &container, atKey: CodingKeys.string)
                        try ValueCoder<Bool>().encodeIfPresent(self.optBool, to: &container, atKey: CodingKeys.optBool)
                        try ValueCoder<Int>().encodeIfPresent(self.optInt, to: &container, atKey: CodingKeys.optInt)
                        try ValueCoder<Double>().encodeIfPresent(self.optDouble, to: &container, atKey: CodingKeys.optDouble)
                        try ValueCoder<String>().encodeIfPresent(self.optString, to: &container, atKey: CodingKeys.optString)
                        try ValueCoder<Bool>().encodeIfPresent(self.impBool, to: &container, atKey: CodingKeys.impBool)
                        try ValueCoder<Int>().encodeIfPresent(self.impInt, to: &container, atKey: CodingKeys.impInt)
                        try ValueCoder<Double>().encodeIfPresent(self.impDouble, to: &container, atKey: CodingKeys.impDouble)
                        try ValueCoder<String>().encodeIfPresent(self.impString, to: &container, atKey: CodingKeys.impString)
                        try ValueCoder<Bool>().encodeIfPresent(self.optGenBool, to: &container, atKey: CodingKeys.optGenBool)
                        try ValueCoder<Int>().encodeIfPresent(self.optGenInt, to: &container, atKey: CodingKeys.optGenInt)
                        try ValueCoder<Double>().encodeIfPresent(self.optGenDouble, to: &container, atKey: CodingKeys.optGenDouble)
                        try ValueCoder<String>().encodeIfPresent(self.optGenString, to: &container, atKey: CodingKeys.optGenString)
                    }
                }

                extension Model {
                    enum CodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "int"
                        case double = "double"
                        case string = "string"
                        case optBool = "optBool"
                        case optInt = "optInt"
                        case optDouble = "optDouble"
                        case optString = "optString"
                        case impBool = "impBool"
                        case impInt = "impInt"
                        case impDouble = "impDouble"
                        case impString = "impString"
                        case optGenBool = "optGenBool"
                        case optGenInt = "optGenInt"
                        case optGenDouble = "optGenDouble"
                        case optGenString = "optGenString"
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

    // Test 4: Enum with common strategies
    struct EnumTests {
        @Codable(commonStrategies: [.codedBy(.valueCoder())])
        @CodedAt("type")
        enum Status {
            case active(since: String)
            case inactive(reason: String)
            case pending(until: String)
        }

        @Test
        func testEnumWithCommonStrategies() throws {
            // Test that associated values can use number-to-string conversion
            let json = """
                {
                    "type": "active",
                    "since": 20250520
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let status = try decoder.decode(Status.self, from: jsonData)

            if case .active(let since) = status {
                #expect(since == "20250520")
            } else {
                Issue.record("Expected status to be .active")
            }

            // Test encoding
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try String(
                data: encoder.encode(status), encoding: .utf8
            )
            #expect(encoded == #"{"since":"20250520","type":"active"}"#)

            // Test decoding other cases with numeric values
            let inactiveJson = """
                {
                    "type": "inactive",
                    "reason": 404
                }
                """
            let inactiveData = try #require(inactiveJson.data(using: .utf8))
            let inactiveStatus = try decoder.decode(
                Status.self, from: inactiveData
            )
            if case .inactive(let reason) = inactiveStatus {
                #expect(reason == "404")
            } else {
                Issue.record("Expected status to be .inactive")
            }

            // Test pending case with numeric until value
            let pendingJson = """
                {
                    "type": "pending",
                    "until": 20251231
                }
                """
            let pendingData = try #require(pendingJson.data(using: .utf8))
            let pendingStatus = try decoder.decode(
                Status.self, from: pendingData
            )
            if case .pending(let until) = pendingStatus {
                #expect(until == "20251231")
            } else {
                Issue.record("Expected status to be .pending")
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable(commonStrategies: [.codedBy(.valueCoder())])
                @CodedAt("type")
                enum Status {
                    case active(since: String)
                    case inactive(reason: String)
                    case pending(until: String)
                }
                """,
                expandedSource:
                    """
                    enum Status {
                        case active(since: String)
                        case inactive(reason: String)
                        case pending(until: String)
                    }

                    extension Status: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                typeContainer = container
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer, let container = container {
                                let typeString: String?
                                do {
                                    typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeString = nil
                                }
                                if let typeString = typeString {
                                    switch typeString {
                                    case "active":
                                        let since: String
                                        since = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.since)
                                        self = .active(since: since)
                                        return
                                    case "inactive":
                                        let reason: String
                                        reason = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.reason)
                                        self = .inactive(reason: reason)
                                        return
                                    case "pending":
                                        let until: String
                                        until = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.until)
                                        self = .pending(until: until)
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

                    extension Status: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            switch self {
                            case .active(since: let since):
                                try typeContainer.encode("active", forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try ValueCoder<String>().encode(since, to: &container, atKey: CodingKeys.since)
                            case .inactive(reason: let reason):
                                try typeContainer.encode("inactive", forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try ValueCoder<String>().encode(reason, to: &container, atKey: CodingKeys.reason)
                            case .pending(until: let until):
                                try typeContainer.encode("pending", forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try ValueCoder<String>().encode(until, to: &container, atKey: CodingKeys.until)
                            }
                        }
                    }

                    extension Status {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                            case since = "since"
                            case reason = "reason"
                            case until = "until"
                        }
                    }
                    """
            )
        }
    }

    // Test 5: Overriding helper coder with common strategies
    struct HelperCoderOverrideTests {
        @Codable(commonStrategies: [.codedBy(.valueCoder())])
        struct ModelWithOverride {
            @CodedBy(CustomIntCoder())
            let id: Int
            let count: Int
        }

        @Test
        func testHelperCoderOverride() throws {
            let json = """
                {
                    "id": "21",
                    "count": "42"
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let model = try decoder.decode(
                ModelWithOverride.self, from: jsonData
            )

            #expect(model.id == 42)  // Due to CustomIntCoder doubling the value
            #expect(model.count == 42)  // Normal ValueCoder behavior

            // Test encoding
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try String(
                data: encoder.encode(model), encoding: .utf8
            )
            #expect(encoded == #"{"count":42,"id":"21"}"#)  // CustomIntCoder halves the value for id
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable(commonStrategies: [.codedBy(.valueCoder())])
                struct ModelWithOverride {
                    @CodedBy(CustomIntCoder())
                    let id: Int
                    let count: Int
                }
                """,
                expandedSource:
                    """
                    struct ModelWithOverride {
                        let id: Int
                        let count: Int
                    }

                    extension ModelWithOverride: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.id = try CustomIntCoder().decode(from: container, forKey: CodingKeys.id)
                            self.count = try ValueCoder<Int>().decode(from: container, forKey: CodingKeys.count)
                        }
                    }

                    extension ModelWithOverride: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try CustomIntCoder().encode(self.id, to: &container, atKey: CodingKeys.id)
                            try ValueCoder<Int>().encode(self.count, to: &container, atKey: CodingKeys.count)
                        }
                    }

                    extension ModelWithOverride {
                        enum CodingKeys: String, CodingKey {
                            case id = "id"
                            case count = "count"
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

private struct CustomIntCoder: HelperCoder {
    func decode(from decoder: Decoder) throws -> Int {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let intValue = Int(stringValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not decode value"
            )
        }
        return intValue * 2  // Double the value during decoding
    }

    func encode(_ value: Int, to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(value / 2))  // Halve the value during encoding
    }
}
