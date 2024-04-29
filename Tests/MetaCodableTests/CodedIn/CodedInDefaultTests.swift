#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedInDefaultTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        if let container = container {
                            do {
                                self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                            } catch {
                                self.value = "some"
                            }
                        } else {
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

    func testWithNoPathOnOptionalType() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @CodedIn
                @Default("some")
                let value: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String?

                    init(value: String? = "some") {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        if let container = container {
                            do {
                                self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                            } catch {
                                self.value = "some"
                            }
                        } else {
                            self.value = "some"
                        }
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

    func testWithSinglePath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let nested_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        if let container = container {
                            if let nested_container = nested_container {
                                do {
                                    self.value = try nested_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                } catch {
                                    self.value = "some"
                                }
                            } else {
                                self.value = "some"
                            }
                        } else {
                            self.value = "some"
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_container.encode(self.value, forKey: CodingKeys.value)
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
                @Default("some")
                @CodedIn("nested")
                let value: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String?

                    init(value: String? = "some") {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let nested_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        if let container = container {
                            if let nested_container = nested_container {
                                do {
                                    self.value = try nested_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                } catch {
                                    self.value = "some"
                                }
                            } else {
                                self.value = "some"
                            }
                        } else {
                            self.value = "some"
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        if let container = container {
                            if let deeply_container = deeply_container {
                                if let nested_deeply_container = nested_deeply_container {
                                    do {
                                        self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                    } catch {
                                        self.value = "some"
                                    }
                                } else {
                                    self.value = "some"
                                }
                            } else {
                                self.value = "some"
                            }
                        } else {
                            self.value = "some"
                        }
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
                @Default("some")
                @CodedIn("deeply", "nested")
                let value: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String?

                    init(value: String? = "some") {
                        self.value = value
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        if let container = container {
                            if let deeply_container = deeply_container {
                                if let nested_deeply_container = nested_deeply_container {
                                    do {
                                        self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                    } catch {
                                        self.value = "some"
                                    }
                                } else {
                                    self.value = "some"
                                }
                            } else {
                                self.value = "some"
                            }
                        } else {
                            self.value = "some"
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
                @Default("some")
                @CodedIn("deeply", "nested")
                let value1: String?
                @Default("some")
                @CodedIn("deeply", "nested")
                let value2: String?
                @CodedIn("deeply")
                let value3: String?
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: String?
                    let value2: String?
                    let value3: String?

                    init(value1: String? = "some", value2: String? = "some", value3: String? = nil) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                        let nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        if let deeply_container = deeply_container {
                            if let nested_deeply_container = nested_deeply_container {
                                do {
                                    self.value1 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "some"
                                }
                                do {
                                    self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "some"
                                }
                            } else {
                                self.value1 = "some"
                                self.value2 = "some"
                            }
                            self.value3 = try deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        } else {
                            self.value1 = "some"
                            self.value2 = "some"
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
                @Default("some")
                @CodedIn("deeply", "nested", "level")
                let value1: String
                @Default("some")
                @CodedIn("deeply", "nested", "level")
                let value2: String?
                @CodedAt("deeply", "nested")
                let value3: String?
                @CodedAt("deeply")
                let value4: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value1: String
                    let value2: String?
                    let value3: String?
                    let value4: String

                    init(value4: String, value3: String? = nil, value1: String = "some", value2: String? = "some") {
                        self.value4 = value4
                        self.value3 = value3
                        self.value1 = value1
                        self.value2 = value2
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let value4_container = ((try? container.decodeNil(forKey: CodingKeys.value4)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value4) : nil
                        let value3_value4_container = try? value4_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value3)
                        let level_value3_value4_container = try? value3_value4_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        if let value4_container = value4_container {
                            self.value4 = try container.decode(String.self, forKey: CodingKeys.value4)
                            if let value3_value4_container = value3_value4_container {
                                self.value3 = try value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                                if let level_value3_value4_container = level_value3_value4_container {
                                    do {
                                        self.value1 = try level_value3_value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                    } catch {
                                        self.value1 = "some"
                                    }
                                    do {
                                        self.value2 = try level_value3_value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                    } catch {
                                        self.value2 = "some"
                                    }
                                } else {
                                    self.value1 = "some"
                                    self.value2 = "some"
                                }
                            } else {
                                self.value1 = "some"
                                self.value2 = "some"
                            }
                        } else {
                            self.value3 = nil
                            self.value1 = "some"
                            self.value2 = "some"
                        }
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value4, forKey: CodingKeys.value4)
                        var value4_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value4)
                        try value4_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        var value3_value4_container = value4_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value3)
                        var level_value3_value4_container = value3_value4_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try level_value3_value4_container.encode(self.value1, forKey: CodingKeys.value1)
                        try level_value3_value4_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value4 = "deeply"
                        case value3 = "nested"
                        case level = "level"
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
                @Default("some")
                @CodedIn("deeply", "nested", "level")
                let value1: String
                @Default("some")
                @CodedIn("deeply", "nested", "level")
                let value2: String?
                @CodedAt("deeply", "nested")
                let value3: String?
                @CodedAt("deeply")
                let value4: String
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    let value1: String
                    let value2: String?
                    let value3: String?
                    let value4: String

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let value4_container = ((try? container.decodeNil(forKey: CodingKeys.value4)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value4) : nil
                        let value3_value4_container = try? value4_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value3)
                        let level_value3_value4_container = try? value3_value4_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        if let value4_container = value4_container {
                            self.value4 = try container.decode(String.self, forKey: CodingKeys.value4)
                            if let value3_value4_container = value3_value4_container {
                                self.value3 = try value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                                if let level_value3_value4_container = level_value3_value4_container {
                                    do {
                                        self.value1 = try level_value3_value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                    } catch {
                                        self.value1 = "some"
                                    }
                                    do {
                                        self.value2 = try level_value3_value4_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                    } catch {
                                        self.value2 = "some"
                                    }
                                } else {
                                    self.value1 = "some"
                                    self.value2 = "some"
                                }
                            } else {
                                self.value1 = "some"
                                self.value2 = "some"
                            }
                        } else {
                            self.value3 = nil
                            self.value1 = "some"
                            self.value2 = "some"
                        }
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value4, forKey: CodingKeys.value4)
                        var value4_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value4)
                        try value4_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        var value3_value4_container = value4_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value3)
                        var level_value3_value4_container = value3_value4_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try level_value3_value4_container.encode(self.value1, forKey: CodingKeys.value1)
                        try level_value3_value4_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value4 = "deeply"
                        case value3 = "nested"
                        case level = "level"
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
