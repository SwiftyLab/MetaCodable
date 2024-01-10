#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class IgnoreCodingTests: XCTestCase {

    func testMisuseOnUninitializedVariable() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreCoding
                var one: String
                @IgnoreDecoding
                var two: String
                @IgnoreCoding
                var three: String { "some" }
                @IgnoreDecoding
                var four: String { get { "some" } }
                @IgnoreCoding
                var five: String = "some" {
                    didSet {
                        print(five)
                    }
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String
                    var two: String
                    var three: String { "some" }
                    var four: String { get { "some" } }
                    var five: String = "some" {
                        didSet {
                            print(five)
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
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case two = "two"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used with uninitialized variable one",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: IgnoreDecoding.misuseID,
                    message:
                        "@IgnoreDecoding can't be used with uninitialized variable two",
                    line: 5, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreDecoding attribute")
                    ]
                ),
            ]
        )
    }

    func testMisuseWithInvalidCombination() throws {
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

    func testDecodingEncodingIgnore() throws {
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

    func testEnumDecodingEncodingIgnore() throws {
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
                        throw DecodingError.typeMismatch(SomeEnum.self, context)
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """
        )
    }

    func testDecodingIgnore() throws {
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

    func testEnumDecodingIgnore() throws {
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
                        throw DecodingError.typeMismatch(SomeEnum.self, context)
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

    func testEncodingIgnore() throws {
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

    func testEnumEncodingIgnore() throws {
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
                            throw DecodingError.typeMismatch(SomeEnum.self, context)
                        }
                        let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                        switch container.allKeys.first.unsafelyUnwrapped {
                        case DecodingKeys.bool:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
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

    func testCombinationWithOtherMacros() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                @IgnoreDecoding
                @CodedIn("deeply", "nested")
                var one: String = "some"
                @IgnoreDecoding
                @CodedAt("deeply", "nested", "key")
                var two: String = "some"
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
                    var two: String = "some"
                    var three: String = "some"
                    var four: String = "some"
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.four = try nested_deeply_container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try nested_deeply_container.decode(String.self, forKey: CodingKeys.three)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.one, forKey: CodingKeys.one)
                        try nested_deeply_container.encode(self.two, forKey: CodingKeys.two)
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

    func testClassCombinationWithOtherMacros() throws {
        assertMacroExpansion(
            """
            @Codable
            class SomeCodable {
                @IgnoreDecoding
                @CodedIn("deeply", "nested")
                var one: String = "some"
                @IgnoreDecoding
                @CodedAt("deeply", "nested", "key")
                var two: String = "some"
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
                    var two: String = "some"
                    var three: String = "some"
                    var four: String = "some"

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        self.four = try nested_deeply_container.decode(String.self, forKey: CodingKeys.two)
                        self.three = try nested_deeply_container.decode(String.self, forKey: CodingKeys.three)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                        var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                        try nested_deeply_container.encode(self.one, forKey: CodingKeys.one)
                        try nested_deeply_container.encode(self.two, forKey: CodingKeys.two)
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

    func testEnumCombinationWithOtherMacros() throws {
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
                            throw DecodingError.typeMismatch(SomeEnum.self, context)
                        }
                        let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                        switch container.allKeys.first.unsafelyUnwrapped {
                        case DecodingKeys.string:
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let _2 = try String(from: contentDecoder)
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
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
#endif
