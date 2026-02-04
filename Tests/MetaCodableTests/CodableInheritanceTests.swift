import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Codable Inheritance Tests")
struct CodableInheritanceTests {
    @Test("Reports error for @Codable misuse", .tags(.classes, .codable, .decoding, .encoding, .enums, .errorHandling, .inheritance, .inherits, .macroExpansion, .structs))
    func misuseOnNonClassDeclaration() throws {
        assertMacroExpansion(
            """
            @Codable
            @Inherits(decodable: false, encodable: false)
            struct SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: Inherits.misuseID,
                    message:
                        "@Inherits only applicable to class declarations",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @Inherits attribute")
                    ]
                )
            ]
        )
    }

    @Suite("Codable Inheritance - No Inheritance")
    struct NoInheritance {
        @Codable
        @Inherits(decodable: false, encodable: false)
        class SomeCodable {
            var value: String = ""

            init() {}
        }

        @Test("Generates macro expansion with @Codable for class", .tags(.classes, .codable, .decoding, .encoding, .enums, .inheritance, .inherits, .macroExpansion))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @Inherits(decodable: false, encodable: false)
                class SomeCodable {
                    var value: String = ""

                    init() { }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable {
                        var value: String = ""

                        init() { }

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }

                    extension SomeCodable: Decodable {
                    }

                    extension SomeCodable: Encodable {
                    }
                    """,
                conformsTo: []
            )
        }

        @Test("Encodes and decodes successfully (CodableInheritanceTests #2)", .tags(.decoding, .encoding, .inheritance, .inherits))
        func decodingAndEncoding() throws {
            let original = SomeCodable()
            original.value = "inheritance_test"
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "inheritance_test")
        }

        @Test("Decodes from JSON successfully (CodableInheritanceTests #4)", .tags(.decoding, .inheritance, .inherits))
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "value": "class_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "class_value")
        }

        @Test("Encodes to JSON successfully", .tags(.encoding, .inheritance, .inherits, .optionals))
        func encodingToJSON() throws {
            let original = SomeCodable()
            original.value = "encoded_class"
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["value"] as? String == "encoded_class")
        }
    }

    @Suite("Codable Inheritance - Explicit")
    struct WithExplicitInheritance {
        class SuperCodable: Swift.Codable {}

        @Codable
        @Inherits(decodable: true, encodable: true)
        class SomeCodable: SuperCodable {
            var value: String = ""

            override init() { super.init() }
        }

        @Test("Generates macro expansion with @Codable for class (CodableInheritanceTests #1)", .tags(.classes, .codable, .decoding, .encoding, .enums, .inheritance, .inherits, .macroExpansion))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @Inherits(decodable: true, encodable: true)
                class SomeCodable: SuperCodable {
                    var value: String = ""

                    override init() { super.init() }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: SuperCodable {
                        var value: String = ""

                        override init() { super.init() }

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            try super.init(from: decoder)
                        }

                        override func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try super.encode(to: encoder)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: []
            )
        }

        @Test("Encodes and decodes successfully (CodableInheritanceTests #3)", .tags(.decoding, .encoding, .inheritance, .inherits))
        func inheritanceDecodingAndEncoding() throws {
            let original = SomeCodable()
            original.value = "inherited_test"
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "inherited_test")
        }

        @Test("Decodes from JSON successfully (CodableInheritanceTests #5)", .tags(.decoding, .inheritance, .inherits))
        func inheritanceFromJSON() throws {
            let jsonStr = """
                {
                    "value": "inherited_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "inherited_value")
        }
    }

    @Suite("Codable Inheritance - Explicit")
    struct WithExplicitPartialInheritance {
        class SuperDecodable: Decodable {}

        @Codable
        @Inherits(decodable: true, encodable: false)
        class SomeCodable: SuperDecodable {
            var value: String = ""

            override init() { super.init() }
        }

        @Test("Generates macro expansion with @Codable for class (CodableInheritanceTests #2)", .tags(.classes, .codable, .decoding, .encoding, .enums, .inheritance, .inherits, .macroExpansion))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @Inherits(decodable: true, encodable: false)
                class SomeCodable: SuperDecodable {
                    var value: String = ""

                    override init() { super.init() }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: SuperDecodable {
                        var value: String = ""

                        override init() { super.init() }

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            try super.init(from: decoder)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }

                    extension SomeCodable: Encodable {
                    }
                    """,
                conformsTo: []
            )
        }
    }
}
