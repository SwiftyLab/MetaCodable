import Foundation
import MetaCodable
import Testing

@testable import PluginCore

struct AccessModifierTests {
    struct Open {
        @Codable
        open class SomeCodable {
            let value: String
        }

        @Test
        func expansion() throws {
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

        @Test
        func openClassDecodingOnly() throws {
            // Open class doesn't have memberwise init, only decoder init
            let jsonStr = """
                {
                    "value": "open_test"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "open_test")
        }

        @Test
        func openClassFromJSON() throws {
            let jsonStr = """
                {
                    "value": "open_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "open_value")
        }
    }

    struct Public {
        @Codable
        @MemberInit
        public struct SomeCodable {
            let value: String
        }

        @Test
        func expansion() throws {
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

        @Test
        func publicStructDecodingAndEncoding() throws {
            let original = SomeCodable(value: "public_test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "public_test")
        }

        @Test
        func publicStructFromJSON() throws {
            let jsonStr = """
                {
                    "value": "public_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "public_value")
        }
    }

    struct Package {
        @Codable
        @MemberInit
        package struct SomeCodable {
            let value: String
        }

        @Test
        func expansion() throws {
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
    }

    struct Others {
        struct Internal {
            @Codable
            @MemberInit
            internal struct SomeCodable {
                let value: String
            }
        }

        struct FilePrivate {
            @Codable
            @MemberInit
            fileprivate struct SomeCodable {
                let value: String
            }
        }

        struct None {
            @Codable
            @MemberInit
            struct SomeCodable {
                let value: String
            }
        }

        @Test(arguments: ["internal", "fileprivate", "private", ""])
        func expansion(_ modifier: String) throws {
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

@Codable
@MemberInit
private struct SomeCodable {
    let value: String
}
