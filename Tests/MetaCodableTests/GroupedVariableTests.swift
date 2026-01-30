import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Grouped Variable Tests")
struct GroupedVariableTests {
    @Suite("Grouped Variable - No Customization")
    struct WithoutAnyCustomization {
        @Codable
        @MemberInit
        struct SomeCodable {
            let one, two, three: String
        }

        @Test("expansion")
        func expansion() throws {
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

        @Test("decoding And Encoding")
        func decodingAndEncoding() throws {
            let original = SomeCodable(
                one: "first", two: "second", three: "third")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.one == "first")
            #expect(decoded.two == "second")
            #expect(decoded.three == "third")
        }

        @Test("decoding From J S O N")
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "one": "value1",
                    "two": "value2",
                    "three": "value3"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.one == "value1")
            #expect(decoded.two == "value2")
            #expect(decoded.three == "value3")
        }

        @Test("encoding To J S O N")
        func encodingToJSON() throws {
            let original = SomeCodable(one: "a", two: "b", three: "c")
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["one"] as? String == "a")
            #expect(json["two"] as? String == "b")
            #expect(json["three"] as? String == "c")
        }
    }

    @Suite("Grouped Variable - Explicit")
    struct WithSomeInitializedWithExplicitTyping {
        @Codable
        @MemberInit
        struct SomeCodable {
            let one, two: String, three: String = ""
        }

        @Test("expansion")
        func expansion() throws {
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
    }

    @Suite("Grouped Variable - Mixed Types")
    struct MixedTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            let one, two: String, three: Int
        }

        @Test("expansion")
        func expansion() throws {
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

    @Suite("Grouped Variable - Explicit")
    struct MixedTypesWithSomeInitializedWithExplicitTyping {
        @Codable
        @MemberInit
        struct SomeCodable {
            let one: String, two: String = "", three: Int
        }

        @Test("expansion")
        func expansion() throws {
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
    }

    @Suite("Grouped Variable - Mixed Types With Some Initialized Without Explicit Typing")
    struct MixedTypesWithSomeInitializedWithoutExplicitTyping {
        @Codable
        @MemberInit
        struct SomeCodable {
            let one: String, two = "", three: Int
        }

        @Test("expansion")
        func expansion() throws {
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
}
