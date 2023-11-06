#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import CodableMacroPlugin

final class GenericsTests: XCTestCase {

    func testSingleGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T> {
                let value: T
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T> {
                    let value: T
                }

                extension GenericCodable: Decodable where T: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(T.self, forKey: CodingKeys.value)
                    }
                }

                extension GenericCodable: Encodable where T: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                """
        )
    }

    func testMultipleGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T, U, V> {
                let value1: T
                let value2: U
                let value3: V
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T, U, V> {
                    let value1: T
                    let value2: U
                    let value3: V
                }

                extension GenericCodable: Decodable where T: Decodable, U: Decodable, V: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value1 = try container.decode(T.self, forKey: CodingKeys.value1)
                        self.value2 = try container.decode(U.self, forKey: CodingKeys.value2)
                        self.value3 = try container.decode(V.self, forKey: CodingKeys.value3)
                    }
                }

                extension GenericCodable: Encodable where T: Encodable, U: Encodable, V: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value1, forKey: CodingKeys.value1)
                        try container.encode(self.value2, forKey: CodingKeys.value2)
                        try container.encode(self.value3, forKey: CodingKeys.value3)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case value1 = "value1"
                        case value2 = "value2"
                        case value3 = "value3"
                    }
                }
                """
        )
    }

    func testMixedGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T> {
                let value: T
                let str: String
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T> {
                    let value: T
                    let str: String
                }

                extension GenericCodable: Decodable where T: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(T.self, forKey: CodingKeys.value)
                        self.str = try container.decode(String.self, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable: Encodable where T: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                        try container.encode(self.str, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case str = "str"
                    }
                }
                """
        )
    }

    func testIgnoredGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T> {
                var value: T { .init() }
                let str: String
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T> {
                    var value: T { .init() }
                    let str: String
                }

                extension GenericCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.str = try container.decode(String.self, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.str, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case str = "str"
                    }
                }
                """
        )
    }

    func testHelperCodedGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T> {
                @CodedBy(TestCoder())
                let value: T
                let str: String
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T> {
                    let value: T
                    let str: String
                }

                extension GenericCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try TestCoder().decode(from: container, forKey: CodingKeys.value)
                        self.str = try container.decode(String.self, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try TestCoder().encode(self.value, to: &container, atKey: CodingKeys.value)
                        try container.encode(self.str, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case str = "str"
                    }
                }
                """
        )
    }

    func testIgnoredEncodingGenericTypeExpansion() throws {
        assertMacroExpansion(
            """
            @Codable
            struct GenericCodable<T> {
                @IgnoreEncoding
                let value: T
                let str: String
            }
            """,
            expandedSource:
                """
                struct GenericCodable<T> {
                    let value: T
                    let str: String
                }

                extension GenericCodable: Decodable where T: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(T.self, forKey: CodingKeys.value)
                        self.str = try container.decode(String.self, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.str, forKey: CodingKeys.str)
                    }
                }

                extension GenericCodable {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                        case str = "str"
                    }
                }
                """
        )
    }
}
#endif
