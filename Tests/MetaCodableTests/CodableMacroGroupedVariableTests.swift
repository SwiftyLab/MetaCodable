import XCTest
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroPlugin

class CodableMacroGroupedVariableTests: XCTestCase {
    func testWithoutAnyCustomization() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let one, two, three: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one, two, three: String
                    init(one: String, two: String, three: String) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try container.decode(String.self, forKey: CodingKeys.three)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    func testWithSomeInitialized() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let one, two: String, three: String = ""
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one, two: String, three: String = ""
                    init(one: String, two: String) {
                        self.one = one
                        self.two = two
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    func testMixedTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let one, two: String, three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one, two: String, three: Int
                    init(one: String, two: String, three: Int) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try container.decode(Int.self, forKey: CodingKeys.three)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    func testMixedTypesWithSomeInitialized() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let one: String, two: String = "", three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String, two: String = "", three: Int
                    init(one: String, three: Int) {
                        self.one = one
                        self.three = three
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.three = try container.decode(Int.self, forKey: CodingKeys.three)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case three = "three"
                    }
                }
                extension SomeCodable: Codable {
                }
                """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
