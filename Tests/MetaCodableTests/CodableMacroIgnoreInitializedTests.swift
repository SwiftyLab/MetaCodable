import XCTest
@testable import CodableMacroPlugin

final class CodableMacroIgnoreInitializedTests: XCTestCase {

    func testIgnore() throws {
        assertMacroExpansion(
            """
            @Codable(ignoreInitialized: true)
            struct SomeCodable {
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

    func testExplicitCodingWithIgnore() throws {
        assertMacroExpansion(
            """
            @Codable(ignoreInitialized: true)
            struct SomeCodable {
                @CodedIn
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
}
