#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import CodableMacroPlugin

final class CodedAsTests: XCTestCase {

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
                        "@CodedAs only applicable to enum-case declarations",
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
                    id: CodedAs.misuseID,
                    message:
                        "@CodedAs can't be used in combination with @IgnoreCoding",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                )
            ]
        )
    }

    func testCustomValue() throws {
        assertMacroExpansion(
            """
            @Codable
            enum SomeEnum {
                case bool(_ variable: Bool)
                @CodedAs("altInt")
                case int(val: Int)
                @CodedAs("altDouble")
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
                        switch container.allKeys.first.unsafelyUnwrapped {
                        case DecodingKeys.bool:
                            let contentDecoder = try container.superDecoder(forKey: DecodingKeys.bool)
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            self = .bool(_: variable)
                        case DecodingKeys.int:
                            let contentDecoder = try container.superDecoder(forKey: DecodingKeys.int)
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case DecodingKeys.double:
                            let contentDecoder = try container.superDecoder(forKey: DecodingKeys.double)
                            let _0 = try Double(from: contentDecoder)
                            self = .double(_: _0)
                        case DecodingKeys.string:
                            let contentDecoder = try container.superDecoder(forKey: DecodingKeys.string)
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let contentDecoder = try container.superDecoder(forKey: DecodingKeys.multi)
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
                        case double = "altDouble"
                        case string = "string"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case double = "altDouble"
                        case string = "string"
                        case multi = "multi"
                    }
                }
                """
        )
    }
}
#endif
