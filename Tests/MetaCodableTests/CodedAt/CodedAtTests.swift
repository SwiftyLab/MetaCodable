import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Coded At Tests")
struct CodedAtTests {
    @Test("Reports error for @CodedAt misuse", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
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
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @CodedAt misuse (CodedAtTests #1)", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnGroupedVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
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

    @Test("Reports error for @CodedAt misuse (CodedAtTests #2)", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
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
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @CodedAt misuse (CodedAtTests #3)", .tags(.codedAt, .codedIn, .errorHandling, .macroExpansion, .structs))
    func misuseInCombinationWithCodedInMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
                @CodedIn
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
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @CodedIn",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can't be used in combination with @CodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
            ]
        )
    }

    @Test("Reports error when @CodedAt is applied multiple times", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt("two")
                @CodedAt("three")
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
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Coded At - With No Path")
    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAtTests #34)", .tags(.codable, .codedAt, .encoding, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt
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
                            self.value = try String(from: decoder)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            try self.value.encode(to: encoder)
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded At - With No Path On Optional Type")
    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAtTests #35)", .tags(.codable, .codedAt, .encoding, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt
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
                            self.value = try String?(from: decoder)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            try self.value.encode(to: encoder)
                        }
                    }
                    """
            )
        }

        @Suite("Coded At - Force Unwrap")
        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct (CodedAtTests #36)", .tags(.codable, .codedAt, .encoding, .macroExpansion, .memberInit, .optionals, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @CodedAt
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
                                self.value = try String?(from: decoder)
                            }
                        }

                        extension SomeCodable: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                try self.value.encode(to: encoder)
                            }
                        }
                        """
                )
            }
        }
    }

    @Suite("Coded At - With Single Path")
    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("key")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAtTests #37)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("key")
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
                            case value = "key"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedAtTests #9)", .tags(.decoding, .encoding))
        func decodingAndEncoding() throws {
            let original = SomeCodable(value: "test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "test")
        }

        @Test("Decodes from JSON successfully (CodedAtTests #28)", .tags(.decoding))
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "key": "custom_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "custom_value")
        }

        @Test("Encodes to JSON successfully (CodedAtTests #5)", .tags(.encoding, .optionals))
        func encodingToJSON() throws {
            let original = SomeCodable(value: "encoded_value")
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["key"] as? String == "encoded_value")
        }
    }

    @Suite("Coded At - With Single Path On Optional Type")
    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("key")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (CodedAtTests #38)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("key")
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
                            case value = "key"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedAtTests #10)", .tags(.decoding, .encoding))
        func decodingAndEncodingWithValue() throws {
            let original = SomeCodable(value: "optional_test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "optional_test")
        }

        @Test("Encodes and decodes successfully (CodedAtTests #11)", .tags(.decoding, .encoding))
        func decodingAndEncodingWithNil() throws {
            let original = SomeCodable(value: nil)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == nil)
        }

        @Test("Decodes from JSON successfully (CodedAtTests #29)", .tags(.decoding))
        func decodingFromJSONWithMissingKey() throws {
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == nil)
        }

        @Suite("Coded At - Force Unwrap")
        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("key")
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct (CodedAtTests #39)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @CodedAt("key")
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
                                case value = "key"
                            }
                        }
                        """
                )
            }
        }
    }

    @Suite("Coded At - With Nested Path")
    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedAtTests #24)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("deeply", "nested", "key")
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
                            case value = "key"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded At - With Nested Path On Optional Type")
    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedAtTests #25)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("deeply", "nested", "key")
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
                            case value = "key"
                            case deeply = "deeply"
                            case nested = "nested"
                        }
                    }
                    """
            )
        }

        @Suite("Coded At - Force Unwrap")
        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key")
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct with nested paths (CodedAtTests #26)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @CodedAt("deeply", "nested", "key")
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
                                case value = "key"
                                case deeply = "deeply"
                                case nested = "nested"
                            }
                        }
                        """
                )
            }
        }
    }

    @Suite("Coded At - With Nested Path On Multi Optional Types")
    struct WithNestedPathOnMultiOptionalTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key1")
            let value1: String?
            @CodedAt("deeply", "nested", "key2")
            let value2: String!
            @CodedAt("deeply", "nested1")
            let value3: String?
            @CodedAt("deeply", "nested2")
            let value4: String!
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedAtTests #27)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("deeply", "nested", "key1")
                    let value1: String?
                    @CodedAt("deeply", "nested", "key2")
                    let value2: String!
                    @CodedAt("deeply", "nested1")
                    let value3: String?
                    @CodedAt("deeply", "nested2")
                    let value4: String!
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: String?
                        let value2: String!
                        let value3: String?
                        let value4: String!

                        init(value1: String? = nil, value2: String! = nil, value3: String? = nil, value4: String! = nil) {
                            self.value1 = value1
                            self.value2 = value2
                            self.value3 = value3
                            self.value4 = value4
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                            let nested_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                            if let deeply_container = deeply_container {
                                self.value3 = try deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                                self.value4 = try deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value4)
                                if let nested_deeply_container = nested_deeply_container {
                                    self.value1 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1)
                                    self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                                } else {
                                    self.value1 = nil
                                    self.value2 = nil
                                }
                            } else {
                                self.value1 = nil
                                self.value2 = nil
                                self.value3 = nil
                                self.value4 = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encodeIfPresent(self.value1, forKey: CodingKeys.value1)
                            try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                            try deeply_container.encodeIfPresent(self.value4, forKey: CodingKeys.value4)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "key1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value2 = "key2"
                            case value3 = "nested1"
                            case value4 = "nested2"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded At - With Nested Path On Mixed Types")
    struct WithNestedPathOnMixedTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key1")
            let value1: String
            @CodedAt("deeply", "nested", "key2")
            let value2: String?
            @CodedAt("deeply", "nested", "key3")
            let value3: String!
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedAtTests #28)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @CodedAt("deeply", "nested", "key1")
                    let value1: String
                    @CodedAt("deeply", "nested", "key2")
                    let value2: String?
                    @CodedAt("deeply", "nested", "key3")
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
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            self.value3 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "key1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value2 = "key2"
                            case value3 = "key3"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded At - Class With Nested Path On Mixed Types")
    struct ClassWithNestedPathOnMixedTypes {
        @Codable
        class SomeCodable {
            @CodedAt("deeply", "nested", "key1")
            let value1: String
            @CodedAt("deeply", "nested", "key2")
            let value2: String?
            @CodedAt("deeply", "nested", "key3")
            let value3: String!
        }

        @Test("Generates macro expansion with @Codable for class with nested paths (CodedAtTests #5)", .tags(.classes, .codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .optionals))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable {
                    @CodedAt("deeply", "nested", "key1")
                    let value1: String
                    @CodedAt("deeply", "nested", "key2")
                    let value2: String?
                    @CodedAt("deeply", "nested", "key3")
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
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            self.value3 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value1 = "key1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value2 = "key2"
                            case value3 = "key3"
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

    @Suite("Coded At - Actor With Nested Path On Mixed Types")
    struct ActorWithNestedPathOnMixedTypes {
        #if swift(<6)
        @MemberInit
        @Codable
        actor SomeCodable {
            @CodedAt("deeply", "nested", "key1")
            let value1: String
            @CodedAt("deeply", "nested", "key2")
            var value2: String?
            @CodedAt("deeply", "nested", "key3")
            var value3: String!
        }
        #endif

        @Test("Generates macro expansion with @Codable for enum with nested paths", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .optionals))
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
                    @CodedAt("deeply", "nested", "key1")
                    let value1: String
                    @CodedAt("deeply", "nested", "key2")
                    var value2: String?
                    @CodedAt("deeply", "nested", "key3")
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
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                            self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            self.value3 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                            try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value1 = "key1"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value2 = "key2"
                            case value3 = "key3"
                        }
                    }

                    extension SomeCodable: \(decodablePrefix)Decodable {
                    }
                    """
            )
        }
    }
}
