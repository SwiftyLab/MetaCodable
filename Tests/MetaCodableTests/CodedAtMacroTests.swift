import XCTest
@testable import CodableMacroPlugin

final class CodedAtMacroTests: XCTestCase {

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
                    id: CodedAt(from: .init("CodedAt"))!.misuseMessageID,
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
                .init(
                    id: CodedAt(from: .init("CodedAt"))!.misuseMessageID,
                    message:
                        "@CodedAt can't be used with grouped variables declaration",
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
                    id: CodedAt(from: .init("CodedAt"))!.misuseMessageID,
                    message:
                        "@CodedAt can't be used in combination with @CodedIn",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedIn().misuseMessageID,
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
                    id: CodedAt(from: .init("CodedAt"))!.misuseMessageID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt(from: .init("CodedAt"))!.misuseMessageID,
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
                    init(from decoder: Decoder) throws {
                        self.value = try String(from: decoder)
                    }
                    func encode(to encoder: Encoder) throws {
                        try self.value.encode(to: encoder)
                    }
                    enum CodingKeys: String, CodingKey {
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNoPathAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default("some")
                @CodedAt
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                    init(value: String = "some") {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        do {
                            self.value = try String(from: decoder)
                        } catch {
                            self.value = "some"
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        try self.value.encode(to: encoder)
                    }
                    enum CodingKeys: String, CodingKey {
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNoPathWithHelperInstance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        self.value = try LossySequenceCoder<[String]>().decode(from: decoder)
                    }
                    func encode(to encoder: Encoder) throws {
                        try LossySequenceCoder<[String]>().encode(self.value, to: encoder)
                    }
                    enum CodingKeys: String, CodingKey {
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNoPathWithHelperInstanceAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String] = ["some"]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        do {
                            self.value = try LossySequenceCoder<[String]>().decode(from: decoder)
                        } catch {
                            self.value = ["some"]
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        try LossySequenceCoder<[String]>().encode(self.value, to: encoder)
                    }
                    enum CodingKeys: String, CodingKey {
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithSinglePath() throws {
        assertMacroExpansion(
            """
            @Codable
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
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithSinglePathAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default("some")
                @CodedAt("key")
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                    init(value: String = "some") {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        } catch {
                            self.value = "some"
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithSinglePathWithHelperInstance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("key")
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let container_valueDecoder = try container.superDecoder(forKey: CodingKeys.value)
                        self.value = try LossySequenceCoder<[String]>().decode(from: container_valueDecoder)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        let container_valueEncoder = container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithSinglePathWithHelperInstanceAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("key")
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String] = ["some"]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            let container_valueDecoder = try container.superDecoder(forKey: CodingKeys.value)
                            self.value = try LossySequenceCoder<[String]>().decode(from: container_valueDecoder)
                        } catch {
                            self.value = ["some"]
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        let container_valueEncoder = container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNestedPath() throws {
        assertMacroExpansion(
            """
            @Codable
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
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNestedPathAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default("some")
                @CodedAt("deeply", "nested", "key")
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                    init(value: String = "some") {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        do {
                            self.value = try nested_deeply_container.decode(String.self, forKey: CodingKeys.value)
                        } catch {
                            self.value = "some"
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNestedPathWithHelperInstance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key")
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_deeply_container_valueDecoder = try nested_deeply_container.superDecoder(forKey: CodingKeys.value)
                        self.value = try LossySequenceCoder<[String]>().decode(from: nested_deeply_container_valueDecoder)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_deeply_container_valueEncoder = nested_deeply_container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: nested_deeply_container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }

    func testWithNestedPathWithHelperInstanceAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key")
                let value: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]
                    init(value: [String] = ["some"]) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        do {
                            let nested_deeply_container_valueDecoder = try nested_deeply_container.superDecoder(forKey: CodingKeys.value)
                            self.value = try LossySequenceCoder<[String]>().decode(from: nested_deeply_container_valueDecoder)
                        } catch {
                            self.value = ["some"]
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_deeply_container_valueEncoder = nested_deeply_container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: nested_deeply_container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "key"
                        case deeply = "deeply"
                        case nested = "nested"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}
