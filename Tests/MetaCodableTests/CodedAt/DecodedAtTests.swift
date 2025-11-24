import MetaCodable
import Testing

@testable import PluginCore

struct DecodedAtTests {
    @Test
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

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt
            let value: String
        }

        @Test
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

    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt
            let value: String?
        }

        @Test
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @DecodedAt
                let value: String!
            }

            @Test
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

    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("key")
            let value: String
        }

        @Test
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

    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("key")
            let value: String?
        }

        @Test
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @DecodedAt("key")
                let value: String!
            }

            @Test
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

    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("deeply", "nested", "key")
            let value: String
        }

        @Test
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

    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @DecodedAt("deeply", "nested", "key")
            let value: String?
        }

        @Test
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
