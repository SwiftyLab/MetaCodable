import XCTest
@testable import CodableMacroPlugin

final class IgnoreCodingMacroTests: XCTestCase {

    func testMisuseOnUninitializedVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                var one: String
                @IgnoreDecoding
                var two: String
                @IgnoreCoding
                var three: String { "some" }
                @IgnoreDecoding
                var four: String { get { "some" } }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String
                    var two: String
                    var three: String {
                        "some"
                    }
                    var four: String {
                        get {
                            "some"
                        }
                    }
                    init(one: String, two: String) {
                        self.one = one
                        self.two = two
                    }
                    init(from decoder: Decoder) throws {
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.two, forKey: CodingKeys.two)
                    }
                    enum CodingKeys: String, CodingKey {
                        case two = "two"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used with uninitialized variable one",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: IgnoreDecoding.misuseID,
                    message:
                        "@IgnoreDecoding can't be used with uninitialized variable two",
                    line: 5, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreDecoding attribute")
                    ]
                ),
            ]
        )
    }

    func testMisuseWithInvalidCombination() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                @CodedAt
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
                    }
                    func encode(to encoder: Encoder) throws {
                    }
                    enum CodingKeys: String, CodingKey {
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used in combination with @CodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @IgnoreCoding",
                    line: 4, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

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
                    }
                    func encode(to encoder: Encoder) throws {
                    }
                    enum CodingKeys: String, CodingKey {
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
                @IgnoreEncoding
                var two: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                    var two: String
                    init(two: String) {
                        self.two = two
                    }
                    init(one: String, two: String) {
                        self.one = one
                        self.two = two
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                    }
                    func encode(to encoder: Encoder) throws {
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testCombinationWithOtherMacros() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreDecoding
                @CodedIn("deeply", "nested")
                var one: String = "some"
                @IgnoreDecoding
                @CodedAt("deeply", "nested", "key")
                var two: String = "some"
                @IgnoreEncoding
                @CodedIn("deeply", "nested")
                var three: String = "some"
                @IgnoreEncoding
                @CodedAt("deeply", "nested", "key")
                var four: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                    var two: String = "some"
                    var three: String = "some"
                    var four: String = "some"
                    init() {
                    }
                    init(one: String) {
                        self.one = one
                    }
                    init(two: String) {
                        self.two = two
                    }
                    init(one: String, two: String) {
                        self.one = one
                        self.two = two
                    }
                    init(four: String) {
                        self.four = four
                    }
                    init(one: String, four: String) {
                        self.one = one
                        self.four = four
                    }
                    init(two: String, four: String) {
                        self.two = two
                        self.four = four
                    }
                    init(one: String, two: String, four: String) {
                        self.one = one
                        self.two = two
                        self.four = four
                    }
                    init(three: String) {
                        self.three = three
                    }
                    init(one: String, three: String) {
                        self.one = one
                        self.three = three
                    }
                    init(two: String, three: String) {
                        self.two = two
                        self.three = three
                    }
                    init(one: String, two: String, three: String) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                    init(four: String, three: String) {
                        self.four = four
                        self.three = three
                    }
                    init(one: String, four: String, three: String) {
                        self.one = one
                        self.four = four
                        self.three = three
                    }
                    init(two: String, four: String, three: String) {
                        self.two = two
                        self.four = four
                        self.three = three
                    }
                    init(one: String, two: String, four: String, three: String) {
                        self.one = one
                        self.two = two
                        self.four = four
                        self.three = three
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.four = try nested_deeply_container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try nested_deeply_container.decode(String.self, forKey: CodingKeys.three)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.one, forKey: CodingKeys.one)
                        try nested_deeply_container.encode(self.two, forKey: CodingKeys.two)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case deeply = "deeply"
                        case nested = "nested"
                        case two = "key"
                        case three = "three"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}
