#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class CodingKeysGenerationTests: XCTestCase {

    func testBacktickExpression() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let `internal`: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let `internal`: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.`internal` = try container.decode(String.self, forKey: CodingKeys.`internal`)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.`internal`, forKey: CodingKeys.`internal`)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case `internal` = "internal"
                    }
                }
                """
        )
    }

    func testReservedNames() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn("associatedtype")
                let val1: String
                @CodedIn("continue")
                let val2: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let val1: String
                    let val2: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let associatedtype_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.`associatedtype`)
                        self.val1 = try associatedtype_container.decode(String.self, forKey: CodingKeys.val1)
                        let continue_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.`continue`)
                        self.val2 = try continue_container.decode(String.self, forKey: CodingKeys.val2)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var associatedtype_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.`associatedtype`)
                        try associatedtype_container.encode(self.val1, forKey: CodingKeys.val1)
                        var continue_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.`continue`)
                        try continue_container.encode(self.val2, forKey: CodingKeys.val2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case val1 = "val1"
                        case `associatedtype` = "associatedtype"
                        case val2 = "val2"
                        case `continue` = "continue"
                    }
                }
                """
        )
    }

    func testNamesBeginningWithNumber() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedAt("1val", "nested")
                let val: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let val: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let key1val_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.key1val)
                        self.val = try key1val_container.decode(String.self, forKey: CodingKeys.val)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var key1val_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.key1val)
                        try key1val_container.encode(self.val, forKey: CodingKeys.val)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case val = "nested"
                        case key1val = "1val"
                    }
                }
                """
        )
    }

    func testNestedPropertiesInSameContainer() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn("nested")
                let val1: String
                @CodedIn("nested")
                let val2: String
                @CodedIn("nested")
                let val3: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let val1: String
                    let val2: String
                    let val3: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.val1 = try nested_container.decode(String.self, forKey: CodingKeys.val1)
                        self.val2 = try nested_container.decode(String.self, forKey: CodingKeys.val2)
                        self.val3 = try nested_container.decode(String.self, forKey: CodingKeys.val3)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_container.encode(self.val1, forKey: CodingKeys.val1)
                        try nested_container.encode(self.val2, forKey: CodingKeys.val2)
                        try nested_container.encode(self.val3, forKey: CodingKeys.val3)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case val1 = "val1"
                        case nested = "nested"
                        case val2 = "val2"
                        case val3 = "val3"
                    }
                }
                """
        )
    }
}
#endif
