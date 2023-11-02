#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import CodableMacroPlugin

final class IgnoreInitializedTests: XCTestCase {

    func testMisuse() throws {
        assertMacroExpansion(
            """
            @IgnoreCodingInitialized
            struct SomeCodable {
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCodingInitialized.misuseID,
                    message:
                        "@IgnoreCodingInitialized must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(
                            message: "Remove @IgnoreCodingInitialized attribute"
                        )
                    ]
                )
            ]
        )
    }

    func testIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: Encoder) throws {
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                    }
                }
                """
        )
    }

    func testExplicitCodingWithIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                """
        )
    }

    func testExplicitCodingWithTopAndDecodeIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
                @IgnoreDecoding
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                """
        )
    }

    func testExplicitCodingWithTopAndEncodeIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
                @IgnoreEncoding
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: Encoder) throws {
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                """
        )
    }
}
#endif
