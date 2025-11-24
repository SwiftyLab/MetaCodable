import MetaCodable
import Testing

@testable import PluginCore

struct EncodedAtTests {
    @Test
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt
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
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test
    func misuseOnGroupedVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt
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

    @Test
    func misuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt
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
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                )
            ]
        )
    }

    @Test
    func misuseInCombinationWithCodedInMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt
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
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt can't be used in combination with @CodedIn",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can't be used in combination with @EncodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
            ]
        )
    }

    @Test
    func misuseInCombinationWithCodedAtMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt
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
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt can't be used in combination with @CodedAt",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @EncodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    @Test
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @EncodedAt("two")
                @EncodedAt("three")
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
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                ),
                .init(
                    id: EncodedAt.misuseID,
                    message:
                        "@EncodedAt can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @EncodedAt attribute")
                    ]
                ),
            ]
        )
    }

    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt
            let value: String
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt
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
                            try self.value.encode(to: encoder)
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

    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt
            let value: String?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt
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
                            try self.value.encode(to: encoder)
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @EncodedAt
                let value: String!
            }

            @Test
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @EncodedAt
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
                                try self.value.encode(to: encoder)
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

    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt("key")
            let value: String
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt("key")
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
                            try container.encode(self.value, forKey: CodingKeys.key)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case key = "key"
                        }
                    }
                    """
            )
        }
    }

    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt("key")
            let value: String?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt("key")
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
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.key)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case key = "key"
                        }
                    }
                    """
            )
        }

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @EncodedAt("key")
                let value: String!
            }

            @Test
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @MemberInit
                    struct SomeCodable {
                        @EncodedAt("key")
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
                                try container.encodeIfPresent(self.value, forKey: CodingKeys.key)
                            }
                        }

                        extension SomeCodable {
                            enum CodingKeys: String, CodingKey {
                                case value = "value"
                                case key = "key"
                            }
                        }
                        """
                )
            }
        }
    }

    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt("deeply", "nested", "key")
            let value: String
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt("deeply", "nested", "key")
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
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.value, forKey: CodingKeys.key)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                            case key = "key"
                        }
                    }
                    """
            )
        }
    }

    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @EncodedAt("deeply", "nested", "key")
            let value: String?
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    @EncodedAt("deeply", "nested", "key")
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
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encodeIfPresent(self.value, forKey: CodingKeys.key)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case deeply = "deeply"
                            case nested = "nested"
                            case key = "key"
                        }
                    }
                    """
            )
        }
    }

    struct WithDecodedAtAndEncodedAt {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("decode_path", "key")
            @EncodedAt("encode_path", "key")
            let value: String
        }

        @Test
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

    struct WithDecodedAtAndEncodedAtOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("decode_path", "key")
            @EncodedAt("encode_path", "key")
            let value: String?
        }

        @Test
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
