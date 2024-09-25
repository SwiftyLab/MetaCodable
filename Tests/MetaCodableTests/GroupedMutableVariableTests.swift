#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class GroupedMutableVariableTests: XCTestCase {
    func testWithoutAnyCustomization() throws {
        assertMacroExpansion(
            """
            @Codable
            @MemberInit
            struct SomeCodable {
                var one, two, three: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one, two, three: String

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
                var one, two: String, three: String = ""
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one, two: String, three: String = ""

                    init(one: String, two: String, three: String = "") {
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
                        do {
                            self.three = try container.decodeIfPresent(String.self, forKey: CodingKeys.three) ?? ""
                        } catch {
                            self.three = ""
                        }
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
    //             var one, two: String, three = ""
    //         }
    //         """,
    //         expandedSource:
    //             """
    //             struct SomeCodable {
    //                 var one, two: String, three = ""
    //                 init(one: String, two: String, three: String) {
    //                     self.one = one
    //                     self.two = two
    //                     self.three = three
    //                 }
    //                 init(from decoder: any Decoder) throws {
    //                     let container = try decoder.container(keyedBy: CodingKeys.self)
    //                     self.one = try container.decode(String.self, forKey: CodingKeys.one)
    //                     self.two = try container.decode(String.self, forKey: CodingKeys.two)
    //                     self.three = try container.decode(String.self, forKey: CodingKeys.three)
    //                 }
    //                 func encode(to encoder: any Encoder) throws {
    //                     var container = encoder.container(keyedBy: CodingKeys.self)
    //                     try container.encode(self.one, forKey: CodingKeys.one)
    //                     try container.encode(self.two, forKey: CodingKeys.two)
    //                     try container.encode(self.three, forKey: CodingKeys.three)
    //                 }
    //                 enum CodingKeys: String, CodingKey {
    //                     case one = "one"
    //                     case two = "two"
    //                     case three = "three"
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
                var one, two: String, three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one, two: String, three: Int

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
                var one: String, two: String = "", three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String, two: String = "", three: Int

                    init(one: String, two: String = "", three: Int) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        do {
                            self.two = try container.decodeIfPresent(String.self, forKey: CodingKeys.two) ?? ""
                        } catch {
                            self.two = ""
                        }
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
                var one: String, two = "", three: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String, two = "", three: Int

                    init(one: String, two: Int = "", three: Int) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        do {
                            self.two = try container.decodeIfPresent(Int.self, forKey: CodingKeys.two) ?? ""
                        } catch {
                            self.two = ""
                        }
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
