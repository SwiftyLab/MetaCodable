import XCTest
@testable import CodableMacroPlugin

final class CodedInMacroTests: XCTestCase {

    func testMisuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedIn
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
                    id: CodedIn().unusedMessageID,
                    message: "Unnecessary use of @CodedIn without arguments",
                    line: 2, column: 5,
                    severity: .warning,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
                .init(
                    id: CodedIn().misuseMessageID,
                    message:
                        "@CodedIn only applicable to variable declarations",
                    line: 2, column: 5,
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
                @CodedIn("two")
                @CodedIn("three")
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
                    id: CodedIn().misuseMessageID,
                    message:
                        "@CodedIn can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                ),
                .init(
                    id: CodedIn().misuseMessageID,
                    message:
                        "@CodedIn can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
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
                @CodedIn
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
                        case value = "value"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            diagnostics: [
                .init(
                    id: CodedIn().unusedMessageID,
                    message: "Unnecessary use of @CodedIn without arguments",
                    line: 3, column: 5,
                    severity: .warning,
                    fixIts: [
                        .init(message: "Remove @CodedIn attribute")
                    ]
                )
            ]
        )
    }

    func testWithNoPathAndDefaultValue() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @Default("some")
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
                        case value = "value"
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
                        case value = "value"
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
                @CodedBy(LossySequenceCoder<[String]>())
                @Default(["some"])
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                    init(value: String = ["some"]) {
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
                        case value = "value"
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
                @CodedIn("nested")
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
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value = try nested_container.decode(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                @CodedIn("nested")
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
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        do {
                            self.value = try nested_container.decode(String.self, forKey: CodingKeys.value)
                        } catch {
                            self.value = "some"
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                @CodedIn("nested")
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
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_container_valueDecoder = try nested_container.superDecoder(forKey: CodingKeys.value)
                        self.value = try LossySequenceCoder<[String]>().decode(from: nested_container_valueDecoder)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_container_valueEncoder = nested_container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: nested_container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                @CodedIn("nested")
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
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        do {
                            let nested_container_valueDecoder = try nested_container.superDecoder(forKey: CodingKeys.value)
                            self.value = try LossySequenceCoder<[String]>().decode(from: nested_container_valueDecoder)
                        } catch {
                            self.value = ["some"]
                        }
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        let nested_container_valueEncoder = nested_container.superEncoder(forKey: CodingKeys.value)
                        try LossySequenceCoder<[String]>().encode(self.value, to: nested_container_valueEncoder)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                @CodedIn("deeply", "nested")
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
                        case value = "value"
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
                @CodedIn("deeply", "nested")
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
                        case value = "value"
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
                @CodedIn("deeply", "nested")
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
                        case value = "value"
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
                @CodedIn("deeply", "nested")
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
                        case value = "value"
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
