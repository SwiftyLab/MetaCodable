import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Explicit Coding Tests")
struct ExplicitCodingTests {
    @Suite("Explicit Coding - Getter Only Variable")
    struct GetterOnlyVariable {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String { "some" }
        }

        @Test("Generates macro expansion with @Codable for struct (ExplicitCodingTests #76)", .tags(.codable, .codedIn, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedIn
                    var value: String { "some" }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String { "some" }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
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
                    """
            )
        }

        @Test("Encodes to JSON successfully (ExplicitCodingTests #14)", .tags(.encoding, .optionals))
        func encodingOnly() throws {
            let original = SomeCodable()
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["value"] as? String == "some")
        }

        @Test("Decodes from JSON successfully (ExplicitCodingTests #48)", .tags(.decoding))
        func decodingEmpty() throws {
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "some")
        }
    }

    @Suite("Explicit Coding - Explicit Getter Only Variable")
    struct ExplicitGetterOnlyVariable {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String {
                "some"
            }
        }

        @Test("Generates macro expansion with @Codable for struct (ExplicitCodingTests #77)", .tags(.codable, .codedIn, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedIn
                    var value: String {
                        get {
                            "some"
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            get {
                                "some"
                            }
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
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
                    """
            )
        }

        @Test("Encodes to JSON successfully (ExplicitCodingTests #15)", .tags(.encoding, .optionals))
        func encodingOnly() throws {
            let original = SomeCodable()
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["value"] as? String == "some")
        }

        @Test("Decodes from JSON successfully (ExplicitCodingTests #49)", .tags(.decoding))
        func decodingEmpty() throws {
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "some")
        }
    }

    @Suite("Explicit Coding - Getter Only Variable With Multi Line Statements")
    struct GetterOnlyVariableWithMultiLineStatements {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test("Generates macro expansion with @Codable for struct (ExplicitCodingTests #78)", .tags(.codable, .codedIn, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedIn
                    var value: String {
                        let val = "Val"
                        return "some\\(val)"
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            let val = "Val"
                            return "some\\(val)"
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
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
                    """
            )
        }

        @Test("Encodes to JSON successfully (ExplicitCodingTests #16)", .tags(.encoding, .optionals))
        func encodingOnly() throws {
            let original = SomeCodable()
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["value"] as? String == "someVal")
        }

        @Test("Decodes from JSON successfully (ExplicitCodingTests #50)", .tags(.decoding))
        func decodingEmpty() throws {
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "someVal")
        }
    }

    @Suite("Explicit Coding - Class Getter Only Variable With Multi Line Statements")
    struct ClassGetterOnlyVariableWithMultiLineStatements {
        @Codable
        class SomeCodable {
            @CodedIn
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test("Generates macro expansion with @Codable for class (ExplicitCodingTests #4)", .tags(.classes, .codable, .codedIn, .encoding, .enums, .macroExpansion))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable {
                    @CodedIn
                    var value: String {
                        let val = "Val"
                        return "some\\(val)"
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable {
                        var value: String {
                            let val = "Val"
                            return "some\\(val)"
                        }

                        required init(from decoder: any Decoder) throws {
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
                    """
            )
        }
    }

    @Suite("Explicit Coding - Computed Property")
    struct ComputedProperty {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String {
                get {
                    "some"
                }
                set {
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (ExplicitCodingTests #79)", .tags(.codable, .codedIn, .encoding, .enums, .macroExpansion, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedIn
                    var value: String {
                        get {
                            "some"
                        }
                        set {
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            get {
                                "some"
                            }
                            set {
                            }
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
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
                    """
            )
        }
    }
}
