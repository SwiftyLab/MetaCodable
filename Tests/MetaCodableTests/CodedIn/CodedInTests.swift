import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Coded In Tests")
struct CodedInTests {
    @Test("Reports error for @CodedIn misuse (CodedInTests #2)", .tags(.codedIn, .errorHandling, .macroExpansion, .structs))
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedIn
                func someFunc() {
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    func someFunc() {
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @CodedIn misuse (CodedInTests #3)", .tags(.codedIn, .errorHandling, .macroExpansion, .structs))
    func misuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedIn
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
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error when @CodedIn is applied multiple times", .tags(.codedIn, .errorHandling, .macroExpansion, .structs))
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedIn("two")
                @CodedIn("three")
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
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Coded In - With No Path")
    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedInTests #66)", .tags(.codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn
                    let value: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String

                        init(value: String) {
                            self.value = value
                        }
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
                    """
            )
        }
    }

    @Suite("Coded In - With No Path On Optional Type")
    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (CodedInTests #67)", .tags(.codable, .codedIn, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn
                    let value: String?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String?

                        init(value: String? = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )

            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn
                    let value: String!
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String!

                        init(value: String! = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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

    @Suite("Coded In - With Single Path")
    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("nested")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #72)", .tags(.codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("nested")
                    let value: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String

                        init(value: String) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.value = try nested_container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded In - With Single Path On Optional Type")
    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("nested")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #73)", .tags(.codable, .codedIn, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("nested")
                    let value: String?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String?

                        init(value: String? = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let nested_container = ((try? container.decodeNil(forKey: CodingKeys.nested)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            if let nested_container = nested_container {
                                self.value = try nested_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                            } else {
                                self.value = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case nested = "nested"
                        }
                    }
                    """
            )

            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("nested")
                    let value: String!
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String!

                        init(value: String! = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let nested_container = ((try? container.decodeNil(forKey: CodingKeys.nested)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            if let nested_container = nested_container {
                                self.value = try nested_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                            } else {
                                self.value = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded In - With Nested Path")
    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #74)", .tags(.codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("deeply", "nested")
                    let value: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String

                        init(value: String) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.value = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedInTests #13)", .tags(.codedIn, .decoding, .encoding))
        func decodingAndEncoding() throws {
            let original = SomeCodable(value: "nested_test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "nested_test")
        }

        @Test("Decodes from JSON successfully (CodedInTests #31)", .tags(.codedIn, .decoding))
        func decodingFromNestedJSON() throws {
            let jsonStr = """
                {
                    "deeply": {
                        "nested": {
                            "value": "deep_value"
                        }
                    }
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "deep_value")
        }

        @Test("Encodes to JSON successfully (CodedInTests #6)", .tags(.codedIn, .encoding, .optionals))
        func encodingToNestedJSON() throws {
            let original = SomeCodable(value: "encoded_nested")
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            let deeply = json["deeply"] as! [String: Any]
            let nested = deeply["nested"] as! [String: Any]
            #expect(nested["value"] as? String == "encoded_nested")
        }
    }

    @Suite("Coded In - With Nested Path On Optional Type")
    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #75)", .tags(.codable, .codedIn, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("deeply", "nested")
                    let value: String?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String?

                        init(value: String? = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                            let nested_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            if let _ = deeply_container {
                                if let nested_deeply_container = nested_deeply_container {
                                    self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                                } else {
                                    self.value = nil
                                }
                            } else {
                                self.value = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }

        @Suite("Coded In - Forced Unwrap")
        struct ForcedUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedIn("deeply", "nested")
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #76)", .tags(.codable, .codedIn, .enums, .macroExpansion, .memberInit, .optionals, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @CodedIn("deeply", "nested")
                        let value: String!
                    }
                    """,
                    expandedSource:
                        """
                        struct SomeCodable {
                            let value: String!

                            init(value: String! = nil) {
                                self.value = value
                            }
                        }

                        extension SomeCodable: Decodable {
                            init(from decoder: any Decoder) throws {
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                                let nested_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                                if let _ = deeply_container {
                                    if let nested_deeply_container = nested_deeply_container {
                                        self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                                    } else {
                                        self.value = nil
                                    }
                                } else {
                                    self.value = nil
                                }
                            }
                        }

                        extension SomeCodable: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                                var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                try nested_deeply_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                            }
                        }

                        extension SomeCodable {
                            enum CodingKeys: String, CodingKey {
                                case value = "value"
                                case deeply = "deeply"
                                case nested = "nested"
                            }
                        }
                        """
                )
            }
        }
    }

    @Suite("Coded In - With Nested Path On Multi Optional Types")
    struct WithNestedPathOnMultiOptionalTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested1")
            let value1: String?
            @CodedIn("deeply", "nested2")
            let value2: String!
            @CodedIn("deeply1")
            let value3: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #77)", .tags(.codable, .codedIn, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("deeply", "nested1")
                    let value1: String?
                    @CodedIn("deeply", "nested2")
                    let value2: String!
                    @CodedIn("deeply1")
                    let value3: String?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: String?
                        let value2: String!
                        let value3: String?

                        init(value1: String? = nil, value2: String! = nil, value3: String? = nil) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                            let nested1_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested1)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1) : nil
                            let nested2_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested2)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2) : nil
                            let deeply1_container = ((try? container.decodeNil(forKey: CodingKeys.deeply1)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply1) : nil
                            if let _ = deeply_container {
                                if let nested1_deeply_container = nested1_deeply_container {
                                    self.value1 = try nested1_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1)
                                } else {
                                    self.value1 = nil
                                }
                                if let nested2_deeply_container = nested2_deeply_container {
                                    self.value2 = try nested2_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                                } else {
                                    self.value2 = nil
                                }
                            } else {
                                self.value1 = nil
                                self.value2 = nil
                            }
                            if let deeply1_container = deeply1_container {
                                self.value3 = try deeply1_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                            } else {
                                self.value3 = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested1_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            try nested1_deeply_container.encodeIfPresent(self.value1, forKey: CodingKeys.value1)
                            var nested2_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2)
                            try nested2_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            var deeply1_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply1)
                            try deeply1_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested1 = "nested1"
                            case value2 = "value2"
                            case nested2 = "nested2"
                            case value3 = "value3"
                            case deeply1 = "deeply1"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded In - With Nested Path On Mixed Types")
    struct WithNestedPathOnMixedTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested1")
            let value1: String
            @CodedIn("deeply", "nested2")
            let value2: String?
            @CodedIn("deeply", "nested3")
            let value3: String!
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedInTests #78)", .tags(.codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedIn("deeply", "nested1")
                    let value1: String
                    @CodedIn("deeply", "nested2")
                    let value2: String?
                    @CodedIn("deeply", "nested3")
                    let value3: String!
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: String
                        let value2: String?
                        let value3: String!

                        init(value1: String, value2: String? = nil, value3: String! = nil) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested1_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            let nested2_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested2)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2) : nil
                            let nested3_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested3)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3) : nil
                            self.value1 = try nested1_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            if let nested2_deeply_container = nested2_deeply_container {
                                self.value2 = try nested2_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            } else {
                                self.value2 = nil
                            }
                            if let nested3_deeply_container = nested3_deeply_container {
                                self.value3 = try nested3_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                            } else {
                                self.value3 = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested1_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            try nested1_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            var nested2_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2)
                            try nested2_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            var nested3_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3)
                            try nested3_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested1 = "nested1"
                            case value2 = "value2"
                            case nested2 = "nested2"
                            case value3 = "value3"
                            case nested3 = "nested3"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded In - Class With Nested Path On Mixed Types")
    struct ClassWithNestedPathOnMixedTypes {
        @Codable
        class SomeCodable {
            @CodedIn("deeply", "nested1")
            let value1: String
            @CodedIn("deeply", "nested2")
            let value2: String?
            @CodedIn("deeply", "nested3")
            let value3: String!
        }

        @Test("Generates macro expansion with @Codable for class with nested paths (CodedInTests #11)", .tags(.classes, .codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .optionals))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable {
                    @CodedIn("deeply", "nested1")
                    let value1: String
                    @CodedIn("deeply", "nested2")
                    let value2: String?
                    @CodedIn("deeply", "nested3")
                    let value3: String!
                }
                """,
                expandedSource:
                    """
                    class SomeCodable {
                        let value1: String
                        let value2: String?
                        let value3: String!

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested1_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            let nested2_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested2)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2) : nil
                            let nested3_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested3)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3) : nil
                            self.value1 = try nested1_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            if let nested2_deeply_container = nested2_deeply_container {
                                self.value2 = try nested2_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            } else {
                                self.value2 = nil
                            }
                            if let nested3_deeply_container = nested3_deeply_container {
                                self.value3 = try nested3_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                            } else {
                                self.value3 = nil
                            }
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested1_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            try nested1_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            var nested2_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2)
                            try nested2_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            var nested3_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3)
                            try nested3_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested1 = "nested1"
                            case value2 = "value2"
                            case nested2 = "nested2"
                            case value3 = "value3"
                            case nested3 = "nested3"
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

    @Suite("Coded In - Actor With Nested Path On Mixed Types")
    struct ActorWithNestedPathOnMixedTypes {
        #if swift(<6)
        @MemberInit
        @Codable
        actor SomeCodable {
            @CodedIn("deeply", "nested1")
            let value1: String
            @CodedIn("deeply", "nested2")
            var value2: String?
            @CodedIn("deeply", "nested3")
            var value3: String!
        }
        #endif

        @Test("Generates macro expansion with @Codable for enum with nested paths (CodedInTests #1)", .tags(.codable, .codedIn, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .optionals))
        func expansion() throws {
            #if swift(>=6)
            let decodablePrefix = "@preconcurrency "
            #else
            let decodablePrefix = ""
            #endif
            assertMacroExpansion(
                """
                @MemberInit
                @Codable
                actor SomeCodable {
                    @CodedIn("deeply", "nested1")
                    let value1: String
                    @CodedIn("deeply", "nested2")
                    var value2: String?
                    @CodedIn("deeply", "nested3")
                    var value3: String!
                }
                """,
                expandedSource:
                    """
                    actor SomeCodable {
                        let value1: String
                        var value2: String?
                        var value3: String!

                        init(value1: String, value2: String? = nil, value3: String! = nil) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                        }

                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested1_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            let nested2_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested2)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2) : nil
                            let nested3_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested3)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3) : nil
                            self.value1 = try nested1_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            if let nested2_deeply_container = nested2_deeply_container {
                                self.value2 = try nested2_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            } else {
                                self.value2 = nil
                            }
                            if let nested3_deeply_container = nested3_deeply_container {
                                self.value3 = try nested3_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                            } else {
                                self.value3 = nil
                            }
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested1_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested1)
                            try nested1_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            var nested2_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested2)
                            try nested2_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            var nested3_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested3)
                            try nested3_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case deeply = "deeply"
                            case nested1 = "nested1"
                            case value2 = "value2"
                            case nested2 = "nested2"
                            case value3 = "value3"
                            case nested3 = "nested3"
                        }
                    }

                    extension SomeCodable: \(decodablePrefix)Decodable {
                    }
                    """
            )
        }
    }
}
