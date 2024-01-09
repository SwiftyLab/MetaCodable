#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class IgnoreInitializedTests: XCTestCase {

    func testMisuse() throws {
        assertMacroExpansion(
            """
            @IgnoreCodingInitialized
            struct SomeCodable {
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var one: String = "some"
                }
                """,
            diagnostics: [
                .init(
                    id: IgnoreCodingInitialized.misuseID,
                    message:
                        "@IgnoreCodingInitialized must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(
                            message: "Remove @IgnoreCodingInitialized attribute"
                        )
                    ]
                )
            ]
        )
    }

    func testIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
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

    func testClassIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            class SomeCodable {
                var one: String = "some"
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    var one: String = "some"

                    required init(from decoder: any Decoder) throws {
                    }

                    func encode(to encoder: any Encoder) throws {
                    }
                }

                extension SomeCodable: Decodable {
                }

                extension SomeCodable: Encodable {
                }
                """
        )
    }

    func testEnumIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            enum SomeEnum {
                case bool(_ variableBool: Bool = true)
                @IgnoreCodingInitialized
                @CodedAs("altInt")
                case int(val: Int = 6)
                @CodedAs("altString")
                case string(String)
                case multi(_ variable: Bool, val: Int, String = "text")
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variableBool: Bool = true)
                    case int(val: Int = 6)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String = "text")
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
                            self = .bool(_: true)
                        case DecodingKeys.int:
                            self = .int(val: 6)
                        case DecodingKeys.string:
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .multi(_: variable, val: val, "text")
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        switch self {
                        case .bool(_: _):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                        case .int(val: _):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                        case .string(let _0):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.string)
                            try _0.encode(to: contentEncoder)
                        case .multi(_: let variable,val: let val,_):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.val)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case variable = "variable"
                        case val = "val"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case multi = "multi"
                    }
                }
                """
        )
    }

    func testEnumCaseIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            enum SomeEnum {
                @IgnoreCodingInitialized
                case bool(_ variableBool: Bool = true)
                @IgnoreCodingInitialized
                @CodedAs("altInt")
                case int(val: Int = 6)
                @CodedAs("altString")
                case string(String)
                case multi(_ variable: Bool, val: Int, String = "text")
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variableBool: Bool = true)
                    case int(val: Int = 6)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String = "text")
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
                            self = .bool(_: true)
                        case DecodingKeys.int:
                            self = .int(val: 6)
                        case DecodingKeys.string:
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let _2 = try String (from: contentDecoder)
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
                        case .bool(_: _):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                        case .int(val: _):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                        case .string(let _0):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.string)
                            try _0.encode(to: contentEncoder)
                        case .multi(_: let variable,val: let val,let _2):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                            try _2.encode(to: contentEncoder)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.val)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case variable = "variable"
                        case val = "val"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case multi = "multi"
                    }
                }
                """
        )
    }

    func testExplicitCodingWithIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
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
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
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

    func testExplicitCodingWithTopAndDecodeIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
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

    func testExplicitCodingWithTopAndEncodeIgnore() throws {
        assertMacroExpansion(
            """
            @Codable
            @IgnoreCodingInitialized
            struct SomeCodable {
                @CodedIn
                @IgnoreEncoding
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
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.one = try container.decode(String.self, forKey: CodingKeys.one)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
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
#endif
