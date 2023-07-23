import XCTest
@testable import CodableMacroPlugin

final class IgnoreCodingMacroTests: XCTestCase {

    func testDecodingEncodingIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                    init() {
                    }
                    init(one: String) {
                        self.one = one
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testDecodingIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreDecoding
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                    init() {
                    }
                    init(one: String) {
                        self.one = one
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testEncodingIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreEncoding
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                    init() {
                    }
                    init(one: String) {
                        self.one = one
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}
