#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class CodedAsEnumTests: XCTestCase {

    func testMisuseOnNonCaseDeclaration() throws {
        assertMacroExpansion(
            """
            enum SomeEnum {
                case bool(_ variable: Bool)
                case int(val: Int)
                case string(String)
                case multi(_ variable: Bool, val: Int, String)

                @CodedAs("test")
                func someFunc() {
                }
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String)
                    func someFunc() {
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs only applicable to enum-case or variable declarations",
                    line: 7, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                )
            ]
        )
    }

    func testDuplicatedMisuse() throws {
        assertMacroExpansion(
            """
            enum SomeEnum {
                @CodedAs("bool1")
                @CodedAs("bool2")
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
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
            ]
        )
    }

    func testMisuseInCombinationWithIgnoreCodingMacro() throws {
        assertMacroExpansion(
            """
            enum SomeEnum {
                @IgnoreCoding
                @CodedAs("bool2")
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
                    id: IgnoreCoding.misuseID,
                    message:
                        "@IgnoreCoding can't be used in combination with @CodedAs",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @IgnoreCoding attribute")
                    ]
                ),
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can't be used in combination with @IgnoreCoding",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
            ]
        )
    }

    func testMisuseOnNonEnumDeclaration() throws {
        assertMacroExpansion(
            """
            @CodedAs<Int>
            struct SomeSomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeSomeCodable {
                    let value: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs only applicable to enum or protocol declarations",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs must be used in combination with @CodedAt",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
            ]
        )
    }

    func testMisuseInCombinationWithCodedByMacro() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            @CodedAs<Int>
            @CodedBy(LossySequenceCoder<[Int]>())
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
                        let type = try LossySequenceCoder<[Int]>().decode(from: container, forKey: CodingKeys.type)
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
                            try LossySequenceCoder<[Int]>().encode(1, to: &typeContainer, atKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
                            try LossySequenceCoder<[Int]>().encode(2, to: &typeContainer, atKey: CodingKeys.type)
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
                """,
            diagnostics: [
                .init(
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can't be used in combination with @CodedBy",
                    line: 3, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
                .init(
                    id: CodedBy.misuseID,
                    message:
                        "@CodedBy can't be used in combination with @CodedAs",
                    line: 4, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedBy attribute")
                    ]
                ),
            ]
        )
    }

    func testExternallyTaggedCustomValue() throws {
        assertMacroExpansion(
            """
            @Codable
            enum SomeEnum {
                case bool(_ variable: Bool)
                @CodedAs("altInt")
                case int(val: Int)
                @CodedAs("altDouble1", "altDouble2")
                case double(_: Double)
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case double(_: Double)
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
                        case DecodingKeys.bool:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            self = .bool(_: variable)
                        case DecodingKeys.int:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case DecodingKeys.double, DecodingKeys.altDouble2:
                            let _0 = try Double(from: contentDecoder)
                            self = .double(_: _0)
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
                        case .bool(_: let variable):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                        case .int(val: let val):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
                        case .double(_: let _0):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.double)
                            try _0.encode(to: contentEncoder)
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
                        case variable = "variable"
                        case bool = "bool"
                        case val = "val"
                        case int = "altInt"
                        case double = "altDouble1"
                        case altDouble2 = "altDouble2"
                        case string = "string"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case double = "altDouble1"
                        case altDouble2 = "altDouble2"
                        case string = "string"
                        case multi = "multi"
                    }
                }
                """
        )
    }

    func testInternallyTaggedCustomValue() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            enum SomeEnum {
                case bool(_ variable: Bool)
                @CodedAs("altInt")
                case int(val: Int)
                @CodedAs("altDouble1", "altDouble2")
                case double(_: Double)
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case double(_: Double)
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
                        case "altInt":
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case "altDouble1", "altDouble2":
                            let _0 = try Double(from: decoder)
                            self = .double(_: _0)
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
                            try typeContainer.encode("altInt", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
                        case .double(_: let _0):
                            try typeContainer.encode("altDouble1", forKey: CodingKeys.type)
                            try _0.encode(to: encoder)
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
                        case type = "type"
                        case variable = "variable"
                        case val = "val"
                    }
                }
                """
        )
    }
}
#endif
