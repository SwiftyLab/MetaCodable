import MetaCodable
import Testing

@testable import PluginCore

@Suite("Decoded At Tests")
struct DecodedAtTests {
    @Test("Reports error for @DecodedAt misuse", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt
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
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @DecodedAt misuse (DecodedAtTests #1)", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnGroupedVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt
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

    @Test("Reports error for @DecodedAt misuse (DecodedAtTests #2)", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt
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
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test("Reports error for @CodedIn misuse", .tags(.codedAt, .codedIn, .errorHandling, .macroExpansion, .structs))
    func misuseInCombinationWithCodedInMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt
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
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt can't be used in combination with @CodedIn",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can't be used in combination with @DecodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
            ]
        )
    }

    @Test("Reports error for @CodedAt misuse (DecodedAtTests #4)", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func misuseInCombinationWithCodedAtMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt
                @CodedAt
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
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt can't be used in combination with @CodedAt",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @DecodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    @Test("Reports error when @DecodedAt is applied multiple times", .tags(.codedAt, .errorHandling, .macroExpansion, .structs))
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @DecodedAt("two")
                @DecodedAt("three")
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
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                ),
                .init(
                    id: DecodedAt.misuseID,
                    message:
                        "@DecodedAt can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @DecodedAt attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Decoded At - With No Path")
    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #40)", .tags(.codable, .codedAt, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt
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

    @Suite("Decoded At - With No Path On Optional Type")
    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #41)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt
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

        @Suite("Decoded At - Force Unwrap")
        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @DecodedAt
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #42)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @DecodedAt
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
    }

    @Suite("Decoded At - With Single Path")
    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("key")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #43)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("key")
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
                            try container.encode(self.value, forKey: CodingKeys.__macro_local_5valuefMu1_)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case __macro_local_5valuefMu1_ = "value"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Decoded At - With Single Path On Optional Type")
    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("key")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #44)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("key")
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
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.__macro_local_5valuefMu1_)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case __macro_local_5valuefMu1_ = "value"
                        }
                    }
                    """
            )
        }

        @Suite("Decoded At - Force Unwrap")
        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @DecodedAt("key")
                let value: String!
            }

            @Test("Generates macro expansion with @Codable for struct (DecodedAtTests #45)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .structs))
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @DecodedAt("key")
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
                                try container.encodeIfPresent(self.value, forKey: CodingKeys.__macro_local_5valuefMu1_)
                            }
                        }

                        extension SomeCodable {
                            enum CodingKeys: String, CodingKey {
                                case value = "key"
                                case __macro_local_5valuefMu1_ = "value"
                            }
                        }
                        """
                )
            }
        }
    }

    @Suite("Decoded At - With Nested Path")
    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("deeply", "nested", "key")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (DecodedAtTests #29)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("deeply", "nested", "key")
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
                            try container.encode(self.value, forKey: CodingKeys.__macro_local_5valuefMu1_)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case deeply = "deeply"
                            case nested = "nested"
                            case __macro_local_5valuefMu1_ = "value"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Decoded At - With Nested Path On Optional Type")
    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("deeply", "nested", "key")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (DecodedAtTests #30)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("deeply", "nested", "key")
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
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.__macro_local_5valuefMu1_)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case deeply = "deeply"
                            case nested = "nested"
                            case __macro_local_5valuefMu1_ = "value"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Decoded At - DecodedAt")
    struct WithDecodedAtAndEncodedAt {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("decode_path", "key")
            @EncodedAt("encode_path", "key")
            let value: String
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (DecodedAtTests #31)", .tags(.codable, .codedAt, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("decode_path", "key")
                    @EncodedAt("encode_path", "key")
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
                            let decodePath_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.decodePath)
                            self.value = try decodePath_container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var encodePath_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.encodePath)
                            try encodePath_container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case decodePath = "decode_path"
                            case encodePath = "encode_path"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Decoded At - DecodedAt")
    struct WithDecodedAtAndEncodedAtOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("decode_path", "key")
            @EncodedAt("encode_path", "key")
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (DecodedAtTests #32)", .tags(.codable, .codedAt, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @DecodedAt("decode_path", "key")
                    @EncodedAt("encode_path", "key")
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
                            let decodePath_container = ((try? container.decodeNil(forKey: CodingKeys.decodePath)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.decodePath) : nil
                            if let decodePath_container = decodePath_container {
                                self.value = try decodePath_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                            } else {
                                self.value = nil
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var encodePath_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.encodePath)
                            try encodePath_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "key"
                            case decodePath = "decode_path"
                            case encodePath = "encode_path"
                        }
                    }
                    """
            )
        }
    }
}
