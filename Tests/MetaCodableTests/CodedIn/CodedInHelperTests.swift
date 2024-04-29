#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedInHelperTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try LossySequenceCoder<[String]>().decode(from: container, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try LossySequenceCoder<[String]>().encode(self.value, to: &container, atKey: CodingKeys.value)
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

    func testWithNoPathOnOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedIn
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = nil) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: container, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value, to: &container, atKey: CodingKeys.value)
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

    func testWithSinglePath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value = try LossySequenceCoder<[String]>().decode(from: nested_container, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try LossySequenceCoder<[String]>().encode(self.value, to: &nested_container, atKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                @CodedIn("nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = nil) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let nested_container = ((try? container.decodeNil(forKey: CodingKeys.nested)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                        if let nested_container = nested_container {
                            self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_container, forKey: CodingKeys.value)
                        } else {
                            self.value = nil
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value, to: &nested_container, atKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case nested = "nested"
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value = try LossySequenceCoder<[String]>().decode(from: nested_deeply_container, forKey: CodingKeys.value)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try LossySequenceCoder<[String]>().encode(self.value, to: &nested_deeply_container, atKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
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
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = nil) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                        let nested_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                        if let deeply_container = deeply_container {
                            if let nested_deeply_container = nested_deeply_container {
                                self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value)
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
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value, to: &nested_deeply_container, atKey: CodingKeys.value)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
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
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value1: [String]?
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value2: [String]?
                @CodedIn("deeply")
                @CodedBy(LossySequenceCoder<[String]>())
                let value3: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: [String]?
                    let value2: [String]?
                    let value3: [String]?

                    init(value1: [String]? = nil, value2: [String]? = nil, value3: [String]? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                        let nested_deeply_container = ((try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                        if let deeply_container = deeply_container {
                            if let nested_deeply_container = nested_deeply_container {
                                self.value1 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value1)
                                self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value2)
                            } else {
                                self.value1 = nil
                                self.value2 = nil
                            }
                            self.value3 = try LossySequenceCoder<[String]>().decodeIfPresent(from: deeply_container, forKey: CodingKeys.value3)
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
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value1, to: &nested_deeply_container, atKey: CodingKeys.value1)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value2, to: &nested_deeply_container, atKey: CodingKeys.value2)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value3, to: &deeply_container, atKey: CodingKeys.value3)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "value2"
                        case value3 = "value3"
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
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value1: [String]
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value2: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: [String]
                    let value2: [String]?

                    init(value1: [String], value2: [String]? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value1 = try LossySequenceCoder<[String]>().decode(from: nested_deeply_container, forKey: CodingKeys.value1)
                        self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try LossySequenceCoder<[String]>().encode(self.value1, to: &nested_deeply_container, atKey: CodingKeys.value1)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value2, to: &nested_deeply_container, atKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "value2"
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
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value1: [String]
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value2: [String]?
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    let value1: [String]
                    let value2: [String]?

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.value1 = try LossySequenceCoder<[String]>().decode(from: nested_deeply_container, forKey: CodingKeys.value1)
                        self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value2)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try LossySequenceCoder<[String]>().encode(self.value1, to: &nested_deeply_container, atKey: CodingKeys.value1)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value2, to: &nested_deeply_container, atKey: CodingKeys.value2)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "value2"
                    }
                }

                extension SomeCodable: Decodable {
                }

                extension SomeCodable: Encodable {
                }
                """
        )
    }
}
#endif
