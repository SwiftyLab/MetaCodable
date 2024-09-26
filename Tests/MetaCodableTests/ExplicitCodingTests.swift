import MetaCodable
import Testing

@testable import PluginCore

struct ExplicitCodingTests {

    struct GetterOnlyVariable {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String { "some" }
        }

        @Test
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
    }

    struct ExplicitGetterOnlyVariable {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String {
                get {
                    "some"
                }
            }
        }

        @Test
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
    }

    struct GetterOnlyVariableWithMultiLineStatements {
        @Codable
        struct SomeCodable {
            @CodedIn
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test
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
    }

    struct ClassGetterOnlyVariableWithMultiLineStatements {
        @Codable
        class SomeCodable {
            @CodedIn
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test
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

        @Test
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
