import Foundation
import MetaCodable
import Testing

@testable import PluginCore

struct IgnoreCodingTests {

    @Test
    func misuseOnUninitializedVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                var one: String
                @IgnoreDecoding
                var two: String
                @IgnoreDecoding
                let three: String?
                @IgnoreCoding
                var four: String { "some" }
                @IgnoreDecoding
                var five: String { get { "some" } }
                @IgnoreCoding
                var six: String = "some" {
                    didSet {
                        print(six)
                    }
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String
                    var two: String
                    let three: String?
                    var four: String { "some" }
                    var five: String { get { "some" } }
                    var six: String = "some" {
                        didSet {
                            print(six)
                        }
                    }
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.two, forKey: CodingKeys.two)
                        try container.encodeIfPresent(self.three, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case two = "two"
                        case three = "three"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used with uninitialized non-optional variable one",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: IgnoreDecoding.misuseID,
                    message:
                        "@IgnoreDecoding can't be used with uninitialized non-optional variable two",
                    line: 5, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreDecoding attribute")
                    ]
                ),
                .init(
                    id: IgnoreDecoding.misuseID,
                    message:
                        "@IgnoreDecoding can't be used with uninitialized non-optional variable three",
                    line: 7, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreDecoding attribute")
                    ]
                ),
            ]
        )
    }

    @Test
    func misuseWithInvalidCombination() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                @CodedAt
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used in combination with @CodedAt",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @IgnoreCoding",
                    line: 4, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    struct DecodingEncodingIgnore {
        @Codable
        struct SomeCodable {
            @IgnoreCoding
            var one: String = "some"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @IgnoreCoding
                    var one: String = "some"
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var one: String = "some"
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }

        struct Optional {
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                var one: String?
                @IgnoreCoding
                var two: String!
                // @IgnoreCoding
                // var three: Swift.Optional<String>
                let four: String
            }

            @Test
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    struct SomeCodable {
                        @IgnoreCoding
                        var one: String?
                        @IgnoreCoding
                        var two: String!
                        @IgnoreCoding
                        var three: Optional<String>
                        let four: String
                    }
                    """,
                    expandedSource:
                        """
                        struct SomeCodable {
                            var one: String?
                            var two: String!
                            var three: Optional<String>
                            let four: String
                        }

                        extension SomeCodable: Decodable {
                            init(from decoder: any Decoder) throws {
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                self.four = try container.decode(String.self, forKey: CodingKeys.four)
                            }
                        }

                        extension SomeCodable: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encode(self.four, forKey: CodingKeys.four)
                            }
                        }

                        extension SomeCodable {
                            enum CodingKeys: String, CodingKey {
                                case four = "four"
                            }
                        }
                        """
                )
            }

            @Test
            func decoding() throws {
                let json = try #require("{\"four\":\"som\"}".data(using: .utf8))
                let obj = try JSONDecoder().decode(SomeCodable.self, from: json)
                #expect(obj.one == nil)
                #expect(obj.two == nil)
                // #expect(obj.three == nil)
                #expect(obj.four == "som")
            }

            @Test
            func encoding() throws {
                let obj = SomeCodable(one: "one", two: "two", four: "some")
                let json = try JSONEncoder().encode(obj)
                let jObj = try JSONSerialization.jsonObject(with: json)
                let dict = try #require(jObj as? [String: Any])
                #expect(dict.count == 1)
                #expect(dict["four"] as? String == "some")
            }
        }
    }

    struct EnumDecodingEncodingIgnore {
        @Codable
        enum SomeEnum {
            @IgnoreCoding
            case bool(_ variableBool: Bool)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum SomeEnum {
                    @IgnoreCoding
                    case bool(_ variableBool: Bool)
                }
                """,
                expandedSource:
                    """
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "No decodable case present."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }
    }

    struct DecodingIgnore {
        @Codable
        struct SomeCodable {
            @IgnoreDecoding
            var one: String = "some"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @IgnoreDecoding
                    var one: String = "some"
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var one: String = "some"
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.one, forKey: CodingKeys.one)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                        }
                    }
                    """
            )
        }
    }

    struct EnumDecodingIgnore {
        @Codable
        enum SomeEnum {
            @IgnoreDecoding
            case bool(_ variableBool: Bool)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum SomeEnum {
                    @IgnoreDecoding
                    case bool(_ variableBool: Bool)
                }
                """,
                expandedSource:
                    """
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "No decodable case present."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .bool(_: let variableBool):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(variableBool, forKey: CodingKeys.variableBool)
                            }
                        }
                    }

                    extension SomeEnum {
                        enum CodingKeys: String, CodingKey {
                            case variableBool = "variableBool"
                            case bool = "bool"
                        }
                    }
                    """
            )
        }
    }

    struct EncodingIgnore {
        @Codable
        struct SomeCodable {
            @IgnoreEncoding
            var one: String = "some"
            @IgnoreEncoding
            var two: String
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @IgnoreEncoding
                    var one: String = "some"
                    @IgnoreEncoding
                    var two: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var one: String = "some"
                        var two: String
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
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                        }
                    }
                    """
            )
        }
    }

    struct EncodingIgnoreWithCondition {
        @Codable
        struct SomeCodable {
            @IgnoreEncoding
            var one: String = "some"
            @IgnoreEncoding(if: \String.isEmpty)
            var two: String
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @IgnoreEncoding
                    var one: String = "some"
                    @IgnoreEncoding(if: \\String.isEmpty)
                    var two: String
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var one: String = "some"
                        var two: String
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
                            if (!{ () -> (_) -> Bool in
                                    \\String.isEmpty
                                }()(self.two)) {
                                try container.encode(self.two, forKey: CodingKeys.two)
                            }
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                        }
                    }
                    """
            )
        }

        @Test
        func ignore() throws {
            let obj = SomeCodable(one: "", two: "")
            let data = try JSONEncoder().encode(obj)
            let value = try JSONSerialization.jsonObject(with: data)
            let dict = try #require(value as? [String: String])
            #expect(dict["one"] == nil)
            #expect(dict["two"] == nil)
        }

        @Test
        func encode() throws {
            let obj = SomeCodable(one: "some", two: "some")
            let data = try JSONEncoder().encode(obj)
            let value = try JSONSerialization.jsonObject(with: data)
            let dict = try #require(value as? [String: String])
            #expect(dict["one"] == nil)
            #expect(dict["two"] == "some")
        }

        @Test
        func decode() throws {
            let json = "{\"one\": \"\", \"two\": \"\"}".data(using: .utf8)!
            let obj = try JSONDecoder().decode(SomeCodable.self, from: json)
            #expect(obj.one == "")
            #expect(obj.two == "")
        }
    }

    struct EnumEncodingIgnore {
        @Codable
        enum SomeEnum {
            @IgnoreEncoding
            case bool(_ variableBool: Bool)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum SomeEnum {
                    @IgnoreEncoding
                    case bool(_ variableBool: Bool)
                }
                """,
                expandedSource:
                    """
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variableBool: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
                                self = .bool(_: variableBool)
                            }
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }

                    extension SomeEnum {
                        enum CodingKeys: String, CodingKey {
                            case variableBool = "variableBool"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case bool = "bool"
                        }
                    }
                    """
            )
        }
    }

    struct EnumEncodingIgnoreWithCondition {
        @Codable
        enum SomeEnum {
            @IgnoreEncoding(if: ignoreEncodingVariable)
            case bool(_ variableBool: Bool)
            @IgnoreEncoding(if: ignoreEncodingVariables)
            case multi(_ variable: Bool, val: Int, String)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                func ignoreEncodingVariable(_ var1: Bool) -> Bool {
                    return var1
                }

                func ignoreEncodingVariables(_ var1: Bool, var2: Int, _ var3: String) -> Bool {
                    return var1
                }

                @Codable
                enum SomeEnum {
                    @IgnoreEncoding(if: ignoreEncodingVariable)
                    case bool(_ variableBool: Bool)
                    @IgnoreEncoding(if: ignoreEncodingVariables)
                    case multi(_ variable: Bool, val: Int, String)
                }
                """,
                expandedSource:
                    """
                    func ignoreEncodingVariable(_ var1: Bool) -> Bool {
                        return var1
                    }

                    func ignoreEncodingVariables(_ var1: Bool, var2: Int, _ var3: String) -> Bool {
                        return var1
                    }
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                        case multi(_ variable: Bool, val: Int, String)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variableBool: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
                                self = .bool(_: variableBool)
                            case DecodingKeys.multi:
                                let variable: Bool
                                let val: Int
                                let _2: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                _2 = try String(from: contentDecoder)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                self = .multi(_: variable, val: val, _2)
                            }
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .bool(_: let variableBool) where (!{ () -> (_) -> Bool in
                                    ignoreEncodingVariable
                                }()(variableBool)):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(variableBool, forKey: CodingKeys.variableBool)
                            case .multi(_: let variable, val: let val, let _2) where (!{ () -> (_, _, _) -> Bool in
                                    ignoreEncodingVariables
                                }()(variable, val, _2)):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                                try _2.encode(to: contentEncoder)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(variable, forKey: CodingKeys.variable)
                                try container.encode(val, forKey: CodingKeys.val)
                            default:
                                break
                            }
                        }
                    }

                    extension SomeEnum {
                        enum CodingKeys: String, CodingKey {
                            case variableBool = "variableBool"
                            case bool = "bool"
                            case variable = "variable"
                            case val = "val"
                            case multi = "multi"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case bool = "bool"
                            case multi = "multi"
                        }
                    }
                    """
            )
        }
    }

    struct EnumEncodingIgnoreWithConditionCombined {
        @Codable
        enum SomeEnum {
            @IgnoreEncoding
            case bool(_ variableBool: Bool)
            @IgnoreEncoding(if: ignoreEncodingVariables)
            case multi(_ variable: Bool, val: Int, String)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                func ignoreEncodingVariables(_ var1: Bool, var2: Int, _ var3: String) -> Bool {
                    return var1
                }

                @Codable
                enum SomeEnum {
                    @IgnoreEncoding
                    case bool(_ variableBool: Bool)
                    @IgnoreEncoding(if: ignoreEncodingVariables)
                    case multi(_ variable: Bool, val: Int, String)
                }
                """,
                expandedSource:
                    """
                    func ignoreEncodingVariables(_ var1: Bool, var2: Int, _ var3: String) -> Bool {
                        return var1
                    }
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                        case multi(_ variable: Bool, val: Int, String)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variableBool: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
                                self = .bool(_: variableBool)
                            case DecodingKeys.multi:
                                let variable: Bool
                                let val: Int
                                let _2: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                _2 = try String(from: contentDecoder)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                self = .multi(_: variable, val: val, _2)
                            }
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .multi(_: let variable, val: let val, let _2) where (!{ () -> (_, _, _) -> Bool in
                                    ignoreEncodingVariables
                                }()(variable, val, _2)):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                                try _2.encode(to: contentEncoder)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(variable, forKey: CodingKeys.variable)
                                try container.encode(val, forKey: CodingKeys.val)
                            default:
                                break
                            }
                        }
                    }

                    extension SomeEnum {
                        enum CodingKeys: String, CodingKey {
                            case variableBool = "variableBool"
                            case variable = "variable"
                            case val = "val"
                            case multi = "multi"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case bool = "bool"
                            case multi = "multi"
                        }
                    }
                    """
            )
        }
    }

    struct CombinationWithOtherMacros {
        @Codable
        struct SomeCodable {
            @IgnoreDecoding
            @CodedIn("deeply", "nested")
            var one: String = "some"
            @IgnoreDecoding
            @CodedAt("deeply", "nested", "key")
            var two: String!
            @IgnoreEncoding
            @CodedIn("deeply", "nested")
            var three: String = "some"
            @IgnoreEncoding
            @CodedAt("deeply", "nested", "key")
            var four: String = "some"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @IgnoreDecoding
                    @CodedIn("deeply", "nested")
                    var one: String = "some"
                    @IgnoreDecoding
                    @CodedAt("deeply", "nested", "key")
                    var two: String!
                    @IgnoreEncoding
                    @CodedIn("deeply", "nested")
                    var three: String = "some"
                    @IgnoreEncoding
                    @CodedAt("deeply", "nested", "key")
                    var four: String = "some"
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var one: String = "some"
                        var two: String!
                        var three: String = "some"
                        var four: String = "some"
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.three = try nested_deeply_container.decode(String.self, forKey: CodingKeys.three)
                            self.four = try nested_deeply_container.decode(String.self, forKey: CodingKeys.two)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.one, forKey: CodingKeys.one)
                            try nested_deeply_container.encodeIfPresent(self.two, forKey: CodingKeys.two)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case deeply = "deeply"
                            case nested = "nested"
                            case two = "key"
                            case three = "three"
                        }
                    }
                    """
            )
        }
    }

    struct ClassCombinationWithOtherMacros {
        @Codable
        class SomeCodable {
            @IgnoreDecoding
            @CodedIn("deeply", "nested")
            var one: String = "some"
            @IgnoreDecoding
            @CodedAt("deeply", "nested", "key")
            var two: String!
            @IgnoreEncoding
            @CodedIn("deeply", "nested")
            var three: String = "some"
            @IgnoreEncoding
            @CodedAt("deeply", "nested", "key")
            var four: String = "some"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable {
                    @IgnoreDecoding
                    @CodedIn("deeply", "nested")
                    var one: String = "some"
                    @IgnoreDecoding
                    @CodedAt("deeply", "nested", "key")
                    var two: String!
                    @IgnoreEncoding
                    @CodedIn("deeply", "nested")
                    var three: String = "some"
                    @IgnoreEncoding
                    @CodedAt("deeply", "nested", "key")
                    var four: String = "some"
                }
                """,
                expandedSource:
                    """
                    class SomeCodable {
                        var one: String = "some"
                        var two: String!
                        var three: String = "some"
                        var four: String = "some"

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            self.three = try nested_deeply_container.decode(String.self, forKey: CodingKeys.three)
                            self.four = try nested_deeply_container.decode(String.self, forKey: CodingKeys.two)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            try nested_deeply_container.encode(self.one, forKey: CodingKeys.one)
                            try nested_deeply_container.encodeIfPresent(self.two, forKey: CodingKeys.two)
                        }

                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case deeply = "deeply"
                            case nested = "nested"
                            case two = "key"
                            case three = "three"
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

    struct EnumCombinationWithOtherMacros {
        @Codable
        enum SomeEnum {
            @IgnoreCoding
            case bool(_ variableBool: Bool)
            @IgnoreDecoding
            @CodedAs("altInt")
            case int(val: Int)
            @IgnoreEncoding
            @CodedAs("altString")
            case string(String)
            @IgnoreEncoding
            case multi(_ variable: Bool, val: Int, String)
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum SomeEnum {
                    @IgnoreCoding
                    case bool(_ variableBool: Bool)
                    @IgnoreDecoding
                    @CodedAs("altInt")
                    case int(val: Int)
                    @IgnoreEncoding
                    @CodedAs("altString")
                    case string(String)
                    @IgnoreEncoding
                    case multi(_ variable: Bool, val: Int, String)
                }
                """,
                expandedSource:
                    """
                    enum SomeEnum {
                        case bool(_ variableBool: Bool)
                        case int(val: Int)
                        case string(String)
                        case multi(_ variable: Bool, val: Int, String)
                    }

                    extension SomeEnum: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.string:
                                let _0: String
                                _0 = try String(from: contentDecoder)
                                self = .string(_0)
                            case DecodingKeys.multi:
                                let variable: Bool
                                let val: Int
                                let _2: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                _2 = try String(from: contentDecoder)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                self = .multi(_: variable, val: val, _2)
                            }
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .int(val: let val):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(val, forKey: CodingKeys.val)
                            default:
                                break
                            }
                        }
                    }

                    extension SomeEnum {
                        enum CodingKeys: String, CodingKey {
                            case val = "val"
                            case int = "altInt"
                            case variable = "variable"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case string = "altString"
                            case multi = "multi"
                        }
                    }
                    """
            )
        }
    }
}

fileprivate func ignoreEncodingVariable(_ var1: Bool) -> Bool {
    return var1
}

fileprivate func ignoreEncodingVariables(
    _ var1: Bool, var2: Int, _ var3: String
) -> Bool {
    return var1
}
