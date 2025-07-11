import MetaCodable
import Testing

@testable import PluginCore

struct CodedAtTests {
    @Test
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

    @Test
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

    @Test
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

    @Test
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

    @Test
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

    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt
            let value: String
        }

        @Test
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

    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt
            let value: String?
        }

        @Test
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt
                let value: String!
            }

            @Test
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

    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("key")
            let value: String
        }

        @Test
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
    }

    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("key")
            let value: String?
        }

        @Test
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("key")
                let value: String!
            }

            @Test
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

    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key")
            let value: String
        }

        @Test
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

    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedAt("deeply", "nested", "key")
            let value: String?
        }

        @Test
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

        struct ForceUnwrap {
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key")
                let value: String!
            }

            @Test
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

        @Test
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

        @Test
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

        @Test
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

        @Test
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
