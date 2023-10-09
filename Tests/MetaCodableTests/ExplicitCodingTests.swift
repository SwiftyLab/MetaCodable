#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import CodableMacroPlugin

final class ExplicitCodingTests: XCTestCase {

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
                    var value: String { "some" }
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
}
#endif
