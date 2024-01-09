#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAtTests: XCTestCase {

    func testMisuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
                func someFunc() {
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    func someFunc() {
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                )
            ]
        )
    }

    func testMisuseOnGroupedVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
                let one, two, three: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one, two, three: String
                }
                """,
            diagnostics: [
                .multiBinding(line: 2, column: 5)
            ]
        )
    }

    func testMisuseOnStaticVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
                static let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    static let value: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                )
            ]
        )
    }

    func testMisuseInCombinationWithCodedInMacro() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt
                @CodedIn
                let one: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @CodedIn",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedIn.misuseID,
                    message:
                        "@CodedIn can't be used in combination with @CodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
            ]
        )
    }

    func testDuplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedAt("two")
                @CodedAt("three")
                let one: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String

                    init(value: String) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        self.value = try String(from: decoder)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        try self.value.encode(to: encoder)
                    }
                }
                """
        )
    }

    func testWithNoPathOnOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt
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
                        self.value = try String?(from: decoder)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        try self.value.encode(to: encoder)
                    }
                }
                """
        )
    }

    func testWithSinglePath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("key")
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
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
                        case value = "key"
                    }
                }
                """
        )
    }

    func testWithSinglePathOnOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("key")
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
                        case value = "key"
                    }
                }
                """
        )
    }

    func testWithNestedPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key")
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String

                    init(value: String) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                """
        )
    }

    func testWithNestedPathOnOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key")
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
                        if (try? container.decodeNil(forKey: CodingKeys.deeply)) == false {
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                                let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                            } else {
                                self.value = nil
                            }
                        } else {
                            self.value = nil
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                """
        )
    }

    func testWithNestedPathOnMultiOptionalTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key1")
                let value1: String?
                @CodedAt("deeply", "nested", "key2")
                let value2: String?
                @CodedAt("deeply", "nested1")
                let value3: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: String?
                    let value2: String?
                    let value3: String?

                    init(value1: String? = nil, value2: String? = nil, value3: String? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if (try? container.decodeNil(forKey: CodingKeys.deeply)) == false {
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                                let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                                self.value1 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1)
                                self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            } else {
                                self.value1 = nil
                                self.value2 = nil
                            }
                            self.value3 = try deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        } else {
                            self.value1 = nil
                            self.value2 = nil
                            self.value3 = nil
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encodeIfPresent(self.value1, forKey: CodingKeys.value1)
                        try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                        try deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "key2"
                        case value3 = "nested1"
                    }
                }
                """
        )
    }

    func testWithNestedPathOnMixedTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedAt("deeply", "nested", "key1")
                let value1: String
                @CodedAt("deeply", "nested", "key2")
                let value2: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: String
                    let value2: String?

                    init(value1: String, value2: String? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                        try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "key2"
                    }
                }
                """
        )
    }

    func testClassWithNestedPathOnMixedTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            class SomeCodable {
                @CodedAt("deeply", "nested", "key1")
                let value1: String
                @CodedAt("deeply", "nested", "key2")
                let value2: String?
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    let value1: String
                    let value2: String?

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                        try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "key2"
                    }
                }

                extension SomeCodable: Decodable {
                }

                extension SomeCodable: Encodable {
                }
                """
        )
    }

    func testActorWithNestedPathOnMixedTypes() throws {
        assertMacroExpansion(
            """
            @MemberInit
            @Codable
            actor SomeCodable {
                @CodedAt("deeply", "nested", "key1")
                let value1: String
                @CodedAt("deeply", "nested", "key2")
                var value2: String?
            }
            """,
            expandedSource:
                """
                actor SomeCodable {
                    let value1: String
                    var value2: String?

                    init(value1: String, value2: String? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                    }

                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value1 = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value1)
                        self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                        try nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "key2"
                    }
                }

                extension SomeCodable: Decodable {
                }
                """
        )
    }
}
#endif
