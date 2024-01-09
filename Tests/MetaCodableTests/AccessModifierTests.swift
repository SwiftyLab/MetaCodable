#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class AccessModifierTests: XCTestCase {

    func testOpen() throws {
        assertMacroExpansion(
            """
            @Codable
            open class SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                open class SomeCodable {
                    let value: String

                    public required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }

                    public func encode(to encoder: any Encoder) throws {
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

    func testPublic() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            public struct SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                public struct SomeCodable {
                    let value: String

                    public init(value: String) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    public init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    public func encode(to encoder: any Encoder) throws {
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

    func testPackage() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            package struct SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                package struct SomeCodable {
                    let value: String

                    package init(value: String) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    package init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    package func encode(to encoder: any Encoder) throws {
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

    func testOthers() throws {
        for modifier in ["internal", "fileprivate", "private", ""] {
            let prefix = modifier.isEmpty ? "" : "\(modifier) "
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                \(prefix)struct SomeCodable {
                    let value: String
                }
                """,
                expandedSource:
                    """
                    \(prefix)struct SomeCodable {
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
}
#endif
