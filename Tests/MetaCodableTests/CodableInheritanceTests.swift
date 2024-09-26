import MetaCodable
import Testing

@testable import PluginCore

struct CodableInheritanceTests {
    @Test
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

    struct NoInheritance {
        @Codable
        @Inherits(decodable: false, encodable: false)
        class SomeCodable {
            var value: String = ""

            init() {}
        }

        @Test
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
    }

    struct WithExplicitInheritance {
        class SuperCodable: Swift.Codable {}

        @Codable
        @Inherits(decodable: true, encodable: true)
        class SomeCodable: SuperCodable {
            var value: String = ""

            override init() { super.init() }
        }

        @Test
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
    }

    struct WithExplicitPartialInheritance {
        class SuperDecodable: Decodable {}

        @Codable
        @Inherits(decodable: true, encodable: false)
        class SomeCodable: SuperDecodable {
            var value: String = ""

            override init() { super.init() }
        }

        @Test
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
