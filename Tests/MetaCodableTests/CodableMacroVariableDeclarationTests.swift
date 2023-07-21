import XCTest
@testable import CodableMacroPlugin

final class CodableMacroVariableDeclarationTests: XCTestCase {

    func testInitializedImmutableVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let value: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String = "some"
                    init() {
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

    func testInitializedMutableVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                var value: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value: String = "some"
                    init() {
                    }
                    init(value: String) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                var value: String { "some" }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value: String {
                        "some"
                    }
                    init() {
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

    func testExplicitGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
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
                    init() {
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

    func testGetterOnlyVariableWithMultiLineStatements() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
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
                    init() {
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

    func testVariableWithPropertyObservers() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                var value1: String {
                    didSet {
                    }
                }
                var value2: String {
                    willSet {
                    }
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value1: String {
                        didSet {
                        }
                    }
                    var value2: String {
                        willSet {
                        }
                    }
                    init(value1: String, value2: String) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value1 = try container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try container.decode(String.self, forKey: CodingKeys.value2)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value1, forKey: CodingKeys.value1)
                        try container.encode(self.value2, forKey: CodingKeys.value2)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value2 = "value2"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testInitializedVariableWithPropertyObservers() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                var value1: String = "some" {
                    didSet {
                    }
                }
                var value2: String = "some" {
                    willSet {
                    }
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value1: String = "some" {
                        didSet {
                        }
                    }
                    var value2: String = "some" {
                        willSet {
                        }
                    }
                    init() {
                    }
                    init(value1: String) {
                        self.value1 = value1
                    }
                    init(value2: String) {
                        self.value2 = value2
                    }
                    init(value1: String, value2: String) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value1 = try container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try container.decode(String.self, forKey: CodingKeys.value2)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value1, forKey: CodingKeys.value1)
                        try container.encode(self.value2, forKey: CodingKeys.value2)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value2 = "value2"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testComputedProperty() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
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
                    init() {
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

    func testOptionalSyntaxVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
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
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testGenericSyntaxOptionalVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let value: Optional<String>
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: Optional<String>
                    init(value: Optional<String> = nil) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}
