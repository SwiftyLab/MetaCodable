import MetaCodable
import Testing

@testable import PluginCore

struct CodedInTests {
    @Test
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

    @Test
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

    @Test
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

    struct WithNoPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn
            let value: String
        }

        @Test
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

    struct WithNoPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn
            let value: String?
        }

        @Test
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

    struct WithSinglePath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("nested")
            let value: String
        }

        @Test
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

    struct WithSinglePathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("nested")
            let value: String?
        }

        @Test
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

    struct WithNestedPath {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested")
            let value: String
        }

        @Test
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
    }

    struct WithNestedPathOnOptionalType {
        @Codable
        @MemberInit
        struct SomeCodable {
            @CodedIn("deeply", "nested")
            let value: String?
        }

        @Test
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
                            if let deeply_container = deeply_container {
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
                            if let deeply_container = deeply_container {
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

        @Test
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
                            if let deeply_container = deeply_container {
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

        @Test
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

        @Test
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
