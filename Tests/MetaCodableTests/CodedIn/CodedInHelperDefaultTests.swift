#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedInHelperDefaultTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: container, forKey: CodingKeys.value) ?? ["some"]
                        } catch {
                            self.value = ["some"]
                        }
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
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = ["some"]) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        do {
                            self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: container, forKey: CodingKeys.value) ?? ["some"]
                        } catch {
                            self.value = ["some"]
                        }
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let nested_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
                            do {
                                self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_container, forKey: CodingKeys.value) ?? ["some"]
                            } catch {
                                self.value = ["some"]
                            }
                        } else {
                            self.value = ["some"]
                        }
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
                @Default(["some"])
                @CodedIn("nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = ["some"]) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let nested_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
                            do {
                                self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_container, forKey: CodingKeys.value) ?? ["some"]
                            } catch {
                                self.value = ["some"]
                            }
                        } else {
                            self.value = ["some"]
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let deeply_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) {
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
                                do {
                                    self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value) ?? ["some"]
                                } catch {
                                    self.value = ["some"]
                                }
                            } else {
                                self.value = ["some"]
                            }
                        } else {
                            self.value = ["some"]
                        }
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
                @Default(["some"])
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: [String]?

                    init(value: [String]? = ["some"]) {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let deeply_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) {
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
                                do {
                                    self.value = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value) ?? ["some"]
                                } catch {
                                    self.value = ["some"]
                                }
                            } else {
                                self.value = ["some"]
                            }
                        } else {
                            self.value = ["some"]
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
                @Default(["some"])
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value1: [String]?
                @Default(["some"])
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value2: [String]?
                @Default(["some"])
                @CodedIn("deeply", "nested")
                let value3: [String]?
                @CodedIn("deeply")
                @CodedBy(LossySequenceCoder<[String]>())
                let value4: [String]?
                @CodedIn("deeply")
                let value5: [String]?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: [String]?
                    let value2: [String]?
                    let value3: [String]?
                    let value4: [String]?
                    let value5: [String]?

                    init(value1: [String]? = ["some"], value2: [String]? = ["some"], value3: [String]? = ["some"], value4: [String]? = nil, value5: [String]? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                        self.value4 = value4
                        self.value5 = value5
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if (try? container.decodeNil(forKey: CodingKeys.deeply)) == false {
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
                                do {
                                    self.value1 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                } catch {
                                    self.value1 = ["some"]
                                }
                                do {
                                    self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                } catch {
                                    self.value2 = ["some"]
                                }
                                do {
                                    self.value3 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value3) ?? ["some"]
                                } catch {
                                    self.value3 = ["some"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                                self.value3 = ["some"]
                            }
                            self.value4 = try LossySequenceCoder<[String]>().decodeIfPresent(from: deeply_container, forKey: CodingKeys.value4)
                            self.value5 = try deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value5)
                        } else {
                            self.value1 = ["some"]
                            self.value2 = ["some"]
                            self.value3 = ["some"]
                            self.value4 = nil
                            self.value5 = nil
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
                        try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value4, to: &deeply_container, atKey: CodingKeys.value4)
                        try deeply_container.encodeIfPresent(self.value5, forKey: CodingKeys.value5)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case value2 = "value2"
                        case value3 = "value3"
                        case value4 = "value4"
                        case value5 = "value5"
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
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedIn("deeply", "nested", "level")
                let value1: [String]
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedIn("deeply", "nested", "level")
                let value2: [String]?
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value3: [String]?
                @CodedIn("deeply", "nested")
                let value4: [String]?
                @CodedIn("deeply")
                @CodedBy(LossySequenceCoder<[String]>())
                let value5: [String]
                @CodedIn("deeply")
                let value6: [String]
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: [String]
                    let value2: [String]?
                    let value3: [String]?
                    let value4: [String]?
                    let value5: [String]
                    let value6: [String]

                    init(value1: [String] = ["some"], value2: [String]? = ["some"], value3: [String]? = nil, value4: [String]? = nil, value5: [String], value6: [String]) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                        self.value4 = value4
                        self.value5 = value5
                        self.value6 = value6
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            if let level_nested_deeply_container = try? nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level) {
                                do {
                                    self.value1 = try LossySequenceCoder<[String]>().decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                } catch {
                                    self.value1 = ["some"]
                                }
                                do {
                                    self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                } catch {
                                    self.value2 = ["some"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                            }
                            self.value3 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value3)
                            self.value4 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value4)
                        } else {
                            self.value1 = ["some"]
                            self.value2 = ["some"]
                            self.value3 = nil
                            self.value4 = nil
                        }
                        self.value5 = try LossySequenceCoder<[String]>().decode(from: deeply_container, forKey: CodingKeys.value5)
                        self.value6 = try deeply_container.decode([String].self, forKey: CodingKeys.value6)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try LossySequenceCoder<[String]>().encode(self.value1, to: &level_nested_deeply_container, atKey: CodingKeys.value1)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value2, to: &level_nested_deeply_container, atKey: CodingKeys.value2)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value3, to: &nested_deeply_container, atKey: CodingKeys.value3)
                        try nested_deeply_container.encodeIfPresent(self.value4, forKey: CodingKeys.value4)
                        try LossySequenceCoder<[String]>().encode(self.value5, to: &deeply_container, atKey: CodingKeys.value5)
                        try deeply_container.encode(self.value6, forKey: CodingKeys.value6)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case level = "level"
                        case value2 = "value2"
                        case value3 = "value3"
                        case value4 = "value4"
                        case value5 = "value5"
                        case value6 = "value6"
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
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedIn("deeply", "nested", "level")
                let value1: [String]
                @Default(["some"])
                @CodedBy(LossySequenceCoder<[String]>())
                @CodedIn("deeply", "nested", "level")
                let value2: [String]?
                @CodedIn("deeply", "nested")
                @CodedBy(LossySequenceCoder<[String]>())
                let value3: [String]?
                @CodedIn("deeply", "nested")
                let value4: [String]?
                @CodedIn("deeply")
                @CodedBy(LossySequenceCoder<[String]>())
                let value5: [String]
                @CodedIn("deeply")
                let value6: [String]
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    let value1: [String]
                    let value2: [String]?
                    let value3: [String]?
                    let value4: [String]?
                    let value5: [String]
                    let value6: [String]

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            if let level_nested_deeply_container = try? nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level) {
                                do {
                                    self.value1 = try LossySequenceCoder<[String]>().decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value1) ?? ["some"]
                                } catch {
                                    self.value1 = ["some"]
                                }
                                do {
                                    self.value2 = try LossySequenceCoder<[String]>().decodeIfPresent(from: level_nested_deeply_container, forKey: CodingKeys.value2) ?? ["some"]
                                } catch {
                                    self.value2 = ["some"]
                                }
                            } else {
                                self.value1 = ["some"]
                                self.value2 = ["some"]
                            }
                            self.value3 = try LossySequenceCoder<[String]>().decodeIfPresent(from: nested_deeply_container, forKey: CodingKeys.value3)
                            self.value4 = try nested_deeply_container.decodeIfPresent([String].self, forKey: CodingKeys.value4)
                        } else {
                            self.value1 = ["some"]
                            self.value2 = ["some"]
                            self.value3 = nil
                            self.value4 = nil
                        }
                        self.value5 = try LossySequenceCoder<[String]>().decode(from: deeply_container, forKey: CodingKeys.value5)
                        self.value6 = try deeply_container.decode([String].self, forKey: CodingKeys.value6)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try LossySequenceCoder<[String]>().encode(self.value1, to: &level_nested_deeply_container, atKey: CodingKeys.value1)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value2, to: &level_nested_deeply_container, atKey: CodingKeys.value2)
                        try LossySequenceCoder<[String]>().encodeIfPresent(self.value3, to: &nested_deeply_container, atKey: CodingKeys.value3)
                        try nested_deeply_container.encodeIfPresent(self.value4, forKey: CodingKeys.value4)
                        try LossySequenceCoder<[String]>().encode(self.value5, to: &deeply_container, atKey: CodingKeys.value5)
                        try deeply_container.encode(self.value6, forKey: CodingKeys.value6)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case level = "level"
                        case value2 = "value2"
                        case value3 = "value3"
                        case value4 = "value4"
                        case value5 = "value5"
                        case value6 = "value6"
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
