#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAtDefaultTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        do {
                            self.value = try String?(from: decoder) ?? "some"
                        } catch {
                            self.value = "some"
                        }
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
                @Default("some")
                @CodedAt
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
                        do {
                            self.value = try String??(from: decoder) ?? "some"
                        } catch {
                            self.value = "some"
                        }
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
                @Default("some")
                @CodedAt("key")
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let deeply_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) {
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
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
                @Default("some")
                @CodedAt("deeply", "nested", "key")
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
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        if let deeply_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) {
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
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
                @Default("some")
                @CodedAt("deeply", "nested", "key1")
                let value1: String?
                @Default("some")
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

                    init(value1: String? = "some", value2: String? = "some", value3: String? = nil) {
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
                            if let nested_deeply_container = try? deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) {
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
                @Default("some")
                @CodedAt("deeply", "nested", "level", "key1")
                let value1: String
                @Default("some")
                @CodedAt("deeply", "nested", "level", "key2")
                let value2: String?
                @CodedAt("deeply", "nested", "level1")
                let value3: String?
                @CodedAt("deeply", "nested1")
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

                    init(value1: String = "some", value2: String? = "some", value3: String? = nil, value4: String) {
                        self.value1 = value1
                        self.value2 = value2
                        self.value3 = value3
                        self.value4 = value4
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
                                    self.value1 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "some"
                                }
                                do {
                                    self.value2 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "some"
                                }
                            } else {
                                self.value1 = "some"
                                self.value2 = "some"
                            }
                            self.value3 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        } else {
                            self.value1 = "some"
                            self.value2 = "some"
                            self.value3 = nil
                        }
                        self.value4 = try deeply_container.decode(String.self, forKey: CodingKeys.value4)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try level_nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                        try level_nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                        try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        try deeply_container.encode(self.value4, forKey: CodingKeys.value4)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case level = "level"
                        case value2 = "key2"
                        case value3 = "level1"
                        case value4 = "nested1"
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
                @CodedAt("deeply", "nested", "level", "key1")
                let value1: String
                @Default("some")
                @CodedAt("deeply", "nested", "level", "key2")
                let value2: String?
                @CodedAt("deeply", "nested", "level1")
                let value3: String?
                @CodedAt("deeply", "nested1")
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
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        if (try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false {
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            if let level_nested_deeply_container = try? nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level) {
                                do {
                                    self.value1 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "some"
                                }
                                do {
                                    self.value2 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "some"
                                }
                            } else {
                                self.value1 = "some"
                                self.value2 = "some"
                            }
                            self.value3 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        } else {
                            self.value1 = "some"
                            self.value2 = "some"
                            self.value3 = nil
                        }
                        self.value4 = try deeply_container.decode(String.self, forKey: CodingKeys.value4)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        var level_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                        try level_nested_deeply_container.encode(self.value1, forKey: CodingKeys.value1)
                        try level_nested_deeply_container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                        try nested_deeply_container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        try deeply_container.encode(self.value4, forKey: CodingKeys.value4)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value1 = "key1"
                        case deeply = "deeply"
                        case nested = "nested"
                        case level = "level"
                        case value2 = "key2"
                        case value3 = "level1"
                        case value4 = "nested1"
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
