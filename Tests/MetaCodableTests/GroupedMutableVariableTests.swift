import MetaCodable
import Testing

@testable import PluginCore

struct GroupedMutableVariableTests {
    struct WithoutAnyCustomization {
        @Codable
        @MemberInit
        struct SomeCodable {
            var one, two, three: String
        }

        @Test
        func expansion() throws {
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
    }

    struct WithSomeInitializedWithExplicitTyping {
        @Codable
        @MemberInit
        struct SomeCodable {
            var one, two: String, three: String = ""
        }

        @Test
        func expansion() throws {
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

                        init(one: String, two: String) {
                            self.one = one
                            self.two = two
                        }

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
    }

    struct MixedTypes {
        @Codable
        @MemberInit
        struct SomeCodable {
            var one, two: String, three: Int
        }

        @Test
        func expansion() throws {
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

    struct MixedTypesWithSomeInitializedWithExplicitTyping {
        @Codable
        @MemberInit
        struct SomeCodable {
            var one: String, two: String = "", three: Int
        }

        @Test
        func expansion() throws {
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

                        init(one: String, three: Int) {
                            self.one = one
                            self.three = three
                        }

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

    @Test
    func mixedTypesWithSomeInitializedWithoutExplicitTyping() throws {
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

                    init(one: String, three: Int) {
                        self.one = one
                        self.three = three
                    }

                    init(one: String, two: Int, three: Int) {
                        self.one = one
                        self.two = two
                        self.three = three
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                        self.two = try container.decode(Int.self, forKey: CodingKeys.two)
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
