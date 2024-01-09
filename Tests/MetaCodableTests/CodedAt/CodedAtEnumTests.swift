#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAtEnumTests: XCTestCase {

    func testMisuseOnNonEnumDeclaration() throws {
        assertMacroExpansion(
            """
            @CodedAt("type")
            enum SomeEnum {
                case bool(_ variable: Bool)
                case int(val: Int)
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String)
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                )
            ]
        )
    }

    func testDuplicatedMisuse() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type1")
            @CodedAt("type2")
            enum SomeEnum {
                case bool(_ variable: Bool)
                case int(val: Int)
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try container.decode(String.self, forKey: CodingKeys.type)
                        switch type {
                        case "bool":
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            self = .bool(_: variable)
                        case "int":
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case "string":
                            let _0 = try String(from: decoder)
                            self = .string(_0)
                        case "multi":
                            let _2 = try String(from: decoder)
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .multi(_: variable, val: val, _2)
                        default:
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(SomeEnum.self, context)
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var typeContainer = container
                        switch self {
                        case .bool(_: let variable):
                            try typeContainer.encode("bool", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                        case .int(val: let val):
                            try typeContainer.encode("int", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
                        case .string(let _0):
                            try typeContainer.encode("string", forKey: CodingKeys.type)
                            try _0.encode(to: encoder)
                        case .multi(_: let variable,val: let val,let _2):
                            try typeContainer.encode("multi", forKey: CodingKeys.type)
                            try _2.encode(to: encoder)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.val)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case type = "type1"
                        case variable = "variable"
                        case val = "val"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can only be applied once per declaration",
                    line: 3, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    func testWithoutExplicitType() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            enum Command {
                case load(key: String)
                case store(key: String, value: Int)
            }
            """,
            expandedSource:
                """
                enum Command {
                    case load(key: String)
                    case store(key: String, value: Int)
                }

                extension Command: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try container.decode(String.self, forKey: CodingKeys.type)
                        switch type {
                        case "load":
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case "store":
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Command.self, context)
                        }
                    }
                }

                extension Command: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var typeContainer = container
                        switch self {
                        case .load(key: let key):
                            try typeContainer.encode("load", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
                            try typeContainer.encode("store", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                            try container.encode(value, forKey: CodingKeys.value)
                        }
                    }
                }

                extension Command {
                    enum CodingKeys: String, CodingKey {
                        case type = "type"
                        case key = "key"
                        case value = "value"
                    }
                }
                """
        )
    }

    func testWithExplicitType() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            @CodedAs<Int>
            enum Command {
                @CodedAs(1)
                case load(key: String)
                @CodedAs(2)
                case store(key: String, value: Int)
            }
            """,
            expandedSource:
                """
                enum Command {
                    case load(key: String)
                    case store(key: String, value: Int)
                }

                extension Command: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try container.decode(Int.self, forKey: CodingKeys.type)
                        switch type {
                        case 1:
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case 2:
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Command.self, context)
                        }
                    }
                }

                extension Command: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var typeContainer = container
                        switch self {
                        case .load(key: let key):
                            try typeContainer.encode(1, forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
                            try typeContainer.encode(2, forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                            try container.encode(value, forKey: CodingKeys.value)
                        }
                    }
                }

                extension Command {
                    enum CodingKeys: String, CodingKey {
                        case type = "type"
                        case key = "key"
                        case value = "value"
                    }
                }
                """
        )
    }

    func testWithHelperExpression() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            @CodedBy(LossySequenceCoder<[Int]>())
            enum Command {
                @CodedAs([1, 2, 3])
                case load(key: String)
                @CodedAs([4, 5, 6])
                case store(key: String, value: Int)
            }
            """,
            expandedSource:
                """
                enum Command {
                    case load(key: String)
                    case store(key: String, value: Int)
                }

                extension Command: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try LossySequenceCoder<[Int]>().decode(from: container, forKey: CodingKeys.type)
                        switch type {
                        case [1, 2, 3]:
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case [4, 5, 6]:
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Command.self, context)
                        }
                    }
                }

                extension Command: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var typeContainer = container
                        switch self {
                        case .load(key: let key):
                            try LossySequenceCoder<[Int]>().encode([1, 2, 3], to: &typeContainer, atKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
                            try LossySequenceCoder<[Int]>().encode([4, 5, 6], to: &typeContainer, atKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                            try container.encode(value, forKey: CodingKeys.value)
                        }
                    }
                }

                extension Command {
                    enum CodingKeys: String, CodingKey {
                        case type = "type"
                        case key = "key"
                        case value = "value"
                    }
                }
                """
        )
    }
}
#endif
