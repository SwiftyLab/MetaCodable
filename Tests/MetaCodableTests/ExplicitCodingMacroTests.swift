import XCTest
@testable import CodableMacroPlugin

final class ExplicitCodingMacroTests: XCTestCase {

    func testGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn
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

    func testExplicitGetterOnlyVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn
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

    func testGetterOnlyVariableWithMultiLineStatements() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn
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

    func testComputedProperty() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedIn
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
}
