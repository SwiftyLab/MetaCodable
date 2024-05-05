#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAtDefaultChoiceTests: XCTestCase {

    func testWithNoPath() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                @Default(ifMissing: "some", forErrors: "another")
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
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
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
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
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
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        if let container = container {
                            do {
                                self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                            } catch {
                                self.value = "another"
                            }
                        } else {
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
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
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        if let container = container {
                            do {
                                self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                            } catch {
                                self.value = "another"
                            }
                        } else {
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
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
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let deeply_containerMissing: Bool
                        if (try? container?.decodeNil(forKey: CodingKeys.deeply)) == false {
                            deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            deeply_containerMissing = false
                        } else {
                            deeply_container = nil
                            deeply_containerMissing = true
                        }
                        let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let nested_deeply_containerMissing: Bool
                        if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                            nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            nested_deeply_containerMissing = false
                        } else {
                            nested_deeply_container = nil
                            nested_deeply_containerMissing = true
                        }
                        if let container = container {
                            if let deeply_container = deeply_container {
                                if let nested_deeply_container = nested_deeply_container {
                                    do {
                                        self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                    } catch {
                                        self.value = "another"
                                    }
                                } else if nested_deeply_containerMissing {
                                    self.value = "some"
                                } else {
                                    self.value = "another"
                                }
                            } else if deeply_containerMissing {
                                self.value = "some"
                            } else {
                                self.value = "another"
                            }
                        } else {
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
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
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let deeply_containerMissing: Bool
                        if (try? container?.decodeNil(forKey: CodingKeys.deeply)) == false {
                            deeply_container = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            deeply_containerMissing = false
                        } else {
                            deeply_container = nil
                            deeply_containerMissing = true
                        }
                        let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let nested_deeply_containerMissing: Bool
                        if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                            nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            nested_deeply_containerMissing = false
                        } else {
                            nested_deeply_container = nil
                            nested_deeply_containerMissing = true
                        }
                        if let container = container {
                            if let deeply_container = deeply_container {
                                if let nested_deeply_container = nested_deeply_container {
                                    do {
                                        self.value = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value) ?? "some"
                                    } catch {
                                        self.value = "another"
                                    }
                                } else if nested_deeply_containerMissing {
                                    self.value = "some"
                                } else {
                                    self.value = "another"
                                }
                            } else if deeply_containerMissing {
                                self.value = "some"
                            } else {
                                self.value = "another"
                            }
                        } else {
                            self.value = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
                @CodedAt("deeply", "nested", "key1")
                let value1: String?
                @Default(ifMissing: "some", forErrors: "another")
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
                        let deeply_container = ((try? container.decodeNil(forKey: CodingKeys.deeply)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply) : nil
                        let nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let nested_deeply_containerMissing: Bool
                        if (try? deeply_container?.decodeNil(forKey: CodingKeys.nested)) == false {
                            nested_deeply_container = try? deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            nested_deeply_containerMissing = false
                        } else {
                            nested_deeply_container = nil
                            nested_deeply_containerMissing = true
                        }
                        if let deeply_container = deeply_container {
                            if let nested_deeply_container = nested_deeply_container {
                                do {
                                    self.value1 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "another"
                                }
                                do {
                                    self.value2 = try nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "another"
                                }
                            } else if nested_deeply_containerMissing {
                                self.value1 = "some"
                                self.value2 = "some"
                            } else {
                                self.value1 = "another"
                                self.value2 = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
                @CodedAt("deeply", "nested", "level", "key1")
                let value1: String
                @Default(ifMissing: "some", forErrors: "another")
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
                        let nested_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                        let level_nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let level_nested_deeply_containerMissing: Bool
                        if (try? nested_deeply_container?.decodeNil(forKey: CodingKeys.level)) == false {
                            level_nested_deeply_container = try? nested_deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                            level_nested_deeply_containerMissing = false
                        } else {
                            level_nested_deeply_container = nil
                            level_nested_deeply_containerMissing = true
                        }
                        if let nested_deeply_container = nested_deeply_container {
                            if let level_nested_deeply_container = level_nested_deeply_container {
                                do {
                                    self.value1 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "another"
                                }
                                do {
                                    self.value2 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "another"
                                }
                            } else if level_nested_deeply_containerMissing {
                                self.value1 = "some"
                                self.value2 = "some"
                            } else {
                                self.value1 = "another"
                                self.value2 = "another"
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
                @Default(ifMissing: "some", forErrors: "another")
                @CodedAt("deeply", "nested", "level", "key1")
                let value1: String
                @Default(ifMissing: "some", forErrors: "another")
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
                        let nested_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.nested)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested) : nil
                        let level_nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                        let level_nested_deeply_containerMissing: Bool
                        if (try? nested_deeply_container?.decodeNil(forKey: CodingKeys.level)) == false {
                            level_nested_deeply_container = try? nested_deeply_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.level)
                            level_nested_deeply_containerMissing = false
                        } else {
                            level_nested_deeply_container = nil
                            level_nested_deeply_containerMissing = true
                        }
                        if let nested_deeply_container = nested_deeply_container {
                            if let level_nested_deeply_container = level_nested_deeply_container {
                                do {
                                    self.value1 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value1) ?? "some"
                                } catch {
                                    self.value1 = "another"
                                }
                                do {
                                    self.value2 = try level_nested_deeply_container.decodeIfPresent(String.self, forKey: CodingKeys.value2) ?? "some"
                                } catch {
                                    self.value2 = "another"
                                }
                            } else if level_nested_deeply_containerMissing {
                                self.value1 = "some"
                                self.value2 = "some"
                            } else {
                                self.value1 = "another"
                                self.value2 = "another"
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
