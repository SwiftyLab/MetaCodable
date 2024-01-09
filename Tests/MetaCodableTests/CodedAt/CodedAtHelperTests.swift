#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAtHelperTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        self.value = try LossySequenceCoder<[String]>().decode(from: decoder)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        try LossySequenceCoder<[String]>().encode(self.value, to: encoder)
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt
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
                        self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: decoder)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value, to: encoder)
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("key")
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key")
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
                        if (try? container.decodeNil(forKey: CodingKeys.deeply)) == false {
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                                let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key1")
                let value1: [String]?
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key2")
                let value2: [String]?
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested1")
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
                        if (try? container.decodeNil(forKey: CodingKeys.deeply)) == false {
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                                let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key1")
                let value1: [String]
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key2")
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
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key1")
                let value1: [String]
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedAt("deeply", "nested", "key2")
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
}
#endif
