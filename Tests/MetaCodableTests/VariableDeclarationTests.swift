#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class VariableDeclarationTests: XCTestCase {

    func testInitializedImmutableVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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

    func testInitializedMutableVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                var value: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value: String = "some"

                    init(value: String = "some") {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                        } catch {
                            self.value = "some"
                        }
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

    func testGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                var value: String { "some" }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var value: String { "some" }

                    init() {
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """
        )
    }

    func testExplicitGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """
        )
    }

    func testGetterOnlyVariableWithMultiLineStatements() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """
        )
    }

    func testVariableWithPropertyObservers() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value1 = try container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try container.decode(String.self, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value1, forKey: CodingKeys.value1)
                        try container.encode(self.value2, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value2 = "value2"
                    }
                }
                """
        )
    }

    func testInitializedVariableWithPropertyObservers() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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

                    init(value1: String = "some", value2: String = "some") {
                        self.value1 = value1
                        self.value2 = value2
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            self.value1 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                        } catch {
                            self.value1 = "some"
                        }
                        do {
                            self.value2 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                        } catch {
                            self.value2 = "some"
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value1, forKey: CodingKeys.value1)
                        try container.encode(self.value2, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value2 = "value2"
                    }
                }
                """
        )
    }

    func testComputedProperty() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """
        )
    }

    func testOptionalSyntaxVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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

    func testGenericSyntaxOptionalVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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
#endif
