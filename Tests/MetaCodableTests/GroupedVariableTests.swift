#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class GroupedVariableTests: XCTestCase {
    func testWithoutAnyCustomization() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try container.decode(String.self, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                """
        )
    }

    func testWithSomeInitializedWithExplicitTyping() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                """
        )
    }

    // func testWithSomeInitializedWithoutExplicitTyping() throws {
    //     XCTExpectFailure("Requires explicit type declaration")
    //     assertMacroExpansion(
    //         """
    //         @Codable
    //         struct SomeCodable {
    //             let one, two: String, three = ""
    //         }
    //         """,
    //         expandedSource:
    //             """
    //             struct SomeCodable {
    //                 let one, two: String, three = ""
    //                 init(one: String, two: String) {
    //                     self.one = one
    //                     self.two = two
    //                 }
    //                 init(from decoder: any Decoder) throws {
    //                     let container = try decoder.container(keyedBy: CodingKeys.self)
    //                     self.one = try container.decode(String.self, forKey: CodingKeys.one)
    //                     self.two = try container.decode(String.self, forKey: CodingKeys.two)
    //                 }
    //                 func encode(to encoder: any Encoder) throws {
    //                     var container = encoder.container(keyedBy: CodingKeys.self)
    //                     try container.encode(self.one, forKey: CodingKeys.one)
    //                     try container.encode(self.two, forKey: CodingKeys.two)
    //                 }
    //                 enum CodingKeys: String, CodingKey {
    //                     case one = "one"
    //                     case two = "two"
    //                 }
    //             }
    //             extension SomeCodable: Codable {
    //             }
    //             """
    //     )
    // }

    func testMixedTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try container.decode(Int.self, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                """
        )
    }

    func testMixedTypesWithSomeInitializedWithExplicitTyping() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
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
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.three = try container.decode(Int.self, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                """
        )
    }

    func testMixedTypesWithSomeInitializedWithoutExplicitTyping() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                let one: String, two = "", three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String, two = "", three: Int

                    init(one: String, three: Int) {
                        self.one = one
                        self.three = three
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.three = try container.decode(Int.self, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.one, forKey: CodingKeys.one)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encode(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case one = "one"
                        case two = "two"
                        case three = "three"
                    }
                }
                """
        )
    }
}
#endif
