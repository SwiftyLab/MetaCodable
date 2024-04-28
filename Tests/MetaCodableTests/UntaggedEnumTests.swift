import MetaCodable
import XCTest

@testable import PluginCore

#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
#endif

final class UntaggedEnumTests: XCTestCase {
    #if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
    func testMisuseOnNonEnumDeclaration() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            struct SomeCodable {
                let val: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let val: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.val = try container.decode(String.self, forKey: CodingKeys.val)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.val, forKey: CodingKeys.val)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case val = "val"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: UnTagged.misuseID,
                    message:
                        "@UnTagged only applicable to enum declarations",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @UnTagged attribute")
                    ]
                )
            ]
        )
    }

    func testMisuseInCombinationWithCodedAtMacro() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            @CodedAt("type")
            enum SomeEnum {
                case bool(Bool)
                case int(Int)
                case string(String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(Bool)
                    case int(Int)
                    case string(String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't decode any case."
                        )
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(SomeEnum.self, context)
                        let _0: Bool
                        do {
                            _0 = try Bool(from: decoder)
                            self = .bool(_0)
                            return
                        } catch {
                            let _0: Int
                            do {
                                _0 = try Int(from: decoder)
                                self = .int(_0)
                                return
                            } catch {
                                let _0: String
                                do {
                                    _0 = try String(from: decoder)
                                    self = .string(_0)
                                    return
                                } catch {
                                    throw __macro_local_13decodingErrorfMu0_
                                }
                            }
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        switch self {
                        case .bool(let _0):
                            try _0.encode(to: encoder)
                        case .int(let _0):
                            try _0.encode(to: encoder)
                        case .string(let _0):
                            try _0.encode(to: encoder)
                        }
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: UnTagged.misuseID,
                    message:
                        "@UnTagged can't be used in combination with @CodedAt",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @UnTagged attribute")
                    ]
                ),
                .init(
                    id: CodedAt.misuseID,
                    message:
                        "@CodedAt can't be used in combination with @UnTagged",
                    line: 3, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAt attribute")
                    ]
                ),
            ]
        )
    }

    func testDuplicatedMisuse() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            @UnTagged
            enum SomeEnum {
                case bool(Bool)
                case int(Int)
                case string(String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(Bool)
                    case int(Int)
                    case string(String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't decode any case."
                        )
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(SomeEnum.self, context)
                        let _0: Bool
                        do {
                            _0 = try Bool(from: decoder)
                            self = .bool(_0)
                            return
                        } catch {
                            let _0: Int
                            do {
                                _0 = try Int(from: decoder)
                                self = .int(_0)
                                return
                            } catch {
                                let _0: String
                                do {
                                    _0 = try String(from: decoder)
                                    self = .string(_0)
                                    return
                                } catch {
                                    throw __macro_local_13decodingErrorfMu0_
                                }
                            }
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        switch self {
                        case .bool(let _0):
                            try _0.encode(to: encoder)
                        case .int(let _0):
                            try _0.encode(to: encoder)
                        case .string(let _0):
                            try _0.encode(to: encoder)
                        }
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: UnTagged.misuseID,
                    message:
                        "@UnTagged should only be applied once per declaration",
                    line: 2, column: 1,
                    severity: .warning,
                    fixIts: [
                        .init(message: "Remove @UnTagged attribute")
                    ]
                ),
                .init(
                    id: UnTagged.misuseID,
                    message:
                        "@UnTagged should only be applied once per declaration",
                    line: 3, column: 1,
                    severity: .warning,
                    fixIts: [
                        .init(message: "Remove @UnTagged attribute")
                    ]
                ),
            ]
        )
    }

    func testWithoutFallbackCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            enum CodableValue {
                case bool(Bool)
                case uint(UInt)
                case int(Int)
                case float(Float)
                case double(Double)
                case string(String)
                case array([Self])
                case dictionary([String: Self])
            }
            """,
            expandedSource:
                """
                enum CodableValue {
                    case bool(Bool)
                    case uint(UInt)
                    case int(Int)
                    case float(Float)
                    case double(Double)
                    case string(String)
                    case array([Self])
                    case dictionary([String: Self])
                }

                extension CodableValue: Decodable {
                    init(from decoder: any Decoder) throws {
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't decode any case."
                        )
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(CodableValue.self, context)
                        let _0: Bool
                        do {
                            _0 = try Bool(from: decoder)
                            self = .bool(_0)
                            return
                        } catch {
                            let _0: UInt
                            do {
                                _0 = try UInt(from: decoder)
                                self = .uint(_0)
                                return
                            } catch {
                                let _0: Int
                                do {
                                    _0 = try Int(from: decoder)
                                    self = .int(_0)
                                    return
                                } catch {
                                    let _0: Float
                                    do {
                                        _0 = try Float(from: decoder)
                                        self = .float(_0)
                                        return
                                    } catch {
                                        let _0: Double
                                        do {
                                            _0 = try Double(from: decoder)
                                            self = .double(_0)
                                            return
                                        } catch {
                                            let _0: String
                                            do {
                                                _0 = try String(from: decoder)
                                                self = .string(_0)
                                                return
                                            } catch {
                                                let _0: [Self]
                                                do {
                                                    _0 = try [Self] (from: decoder)
                                                    self = .array(_0)
                                                    return
                                                } catch {
                                                    let _0: [String: Self]
                                                    do {
                                                        _0 = try [String: Self] (from: decoder)
                                                        self = .dictionary(_0)
                                                        return
                                                    } catch {
                                                        throw __macro_local_13decodingErrorfMu0_
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                extension CodableValue: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        switch self {
                        case .bool(let _0):
                            try _0.encode(to: encoder)
                        case .uint(let _0):
                            try _0.encode(to: encoder)
                        case .int(let _0):
                            try _0.encode(to: encoder)
                        case .float(let _0):
                            try _0.encode(to: encoder)
                        case .double(let _0):
                            try _0.encode(to: encoder)
                        case .string(let _0):
                            try _0.encode(to: encoder)
                        case .array(let _0):
                            try _0.encode(to: encoder)
                        case .dictionary(let _0):
                            try _0.encode(to: encoder)
                        }
                    }
                }
                """
        )
    }

    func testWithFallbackCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            enum CodableValue {
                case bool(Bool)
                case uint(UInt)
                case int(Int)
                case float(Float)
                case double(Double)
                case string(String)
                case array([Self])
                case dictionary([String: Self])
                case `nil`
            }
            """,
            expandedSource:
                """
                enum CodableValue {
                    case bool(Bool)
                    case uint(UInt)
                    case int(Int)
                    case float(Float)
                    case double(Double)
                    case string(String)
                    case array([Self])
                    case dictionary([String: Self])
                    case `nil`
                }

                extension CodableValue: Decodable {
                    init(from decoder: any Decoder) throws {
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't decode any case."
                        )
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(CodableValue.self, context)
                        let _0: Bool
                        do {
                            _0 = try Bool(from: decoder)
                            self = .bool(_0)
                            return
                        } catch {
                            let _0: UInt
                            do {
                                _0 = try UInt(from: decoder)
                                self = .uint(_0)
                                return
                            } catch {
                                let _0: Int
                                do {
                                    _0 = try Int(from: decoder)
                                    self = .int(_0)
                                    return
                                } catch {
                                    let _0: Float
                                    do {
                                        _0 = try Float(from: decoder)
                                        self = .float(_0)
                                        return
                                    } catch {
                                        let _0: Double
                                        do {
                                            _0 = try Double(from: decoder)
                                            self = .double(_0)
                                            return
                                        } catch {
                                            let _0: String
                                            do {
                                                _0 = try String(from: decoder)
                                                self = .string(_0)
                                                return
                                            } catch {
                                                let _0: [Self]
                                                do {
                                                    _0 = try [Self] (from: decoder)
                                                    self = .array(_0)
                                                    return
                                                } catch {
                                                    let _0: [String: Self]
                                                    do {
                                                        _0 = try [String: Self] (from: decoder)
                                                        self = .dictionary(_0)
                                                        return
                                                    } catch {
                                                        do {
                                                            self = .`nil`
                                                            return
                                                        } catch {
                                                            throw __macro_local_13decodingErrorfMu0_
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                extension CodableValue: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        switch self {
                        case .bool(let _0):
                            try _0.encode(to: encoder)
                        case .uint(let _0):
                            try _0.encode(to: encoder)
                        case .int(let _0):
                            try _0.encode(to: encoder)
                        case .float(let _0):
                            try _0.encode(to: encoder)
                        case .double(let _0):
                            try _0.encode(to: encoder)
                        case .string(let _0):
                            try _0.encode(to: encoder)
                        case .array(let _0):
                            try _0.encode(to: encoder)
                        case .dictionary(let _0):
                            try _0.encode(to: encoder)
                        case .`nil`:
                            break
                        }
                    }
                }
                """
        )
    }

    func testNestedDecoding() throws {
        assertMacroExpansion(
            """
            @Codable
            @UnTagged
            enum SomeEnum {
                case bool(_ variable: Bool)
                case int(val: Int)
                case string(String)
                case multiOpt(_ variable: Bool?, val: Int?, str: String?)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case string(String)
                    case multiOpt(_ variable: Bool?, val: Int?, str: String?)
                    case multi(_ variable: Bool, val: Int, String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't decode any case."
                        )
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(SomeEnum.self, context)
                        let variable: Bool
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        do {
                            if let container = container {
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            } else {
                                throw __macro_local_13decodingErrorfMu0_
                            }
                            self = .bool(_: variable)
                            return
                        } catch {
                            let val: Int
                            do {
                                if let container = container {
                                    val = try container.decode(Int.self, forKey: CodingKeys.val)
                                } else {
                                    throw __macro_local_13decodingErrorfMu0_
                                }
                                self = .int(val: val)
                                return
                            } catch {
                                let _0: String
                                do {
                                    _0 = try String(from: decoder)
                                    self = .string(_0)
                                    return
                                } catch {
                                    let variable: Bool?
                                    let val: Int?
                                    let str: String?
                                    do {
                                        if let container = container {
                                            variable = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.variable)
                                            val = try container.decodeIfPresent(Int.self, forKey: CodingKeys.val)
                                            str = try container.decodeIfPresent(String.self, forKey: CodingKeys.str)
                                        } else {
                                            throw __macro_local_13decodingErrorfMu0_
                                        }
                                        self = .multiOpt(_: variable, val: val, str: str)
                                        return
                                    } catch {
                                        let variable: Bool
                                        let val: Int
                                        let _2: String
                                        do {
                                            if let container = container {
                                                _2 = try String(from: decoder)
                                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                            } else {
                                                throw __macro_local_13decodingErrorfMu0_
                                            }
                                            self = .multi(_: variable, val: val, _2)
                                            return
                                        } catch {
                                            throw __macro_local_13decodingErrorfMu0_
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        switch self {
                        case .bool(_: let variable):
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                        case .int(val: let val):
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
                        case .string(let _0):
                            try _0.encode(to: encoder)
                        case .multiOpt(_: let variable,val: let val,str: let str):
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(variable, forKey: CodingKeys.variable)
                            try container.encodeIfPresent(val, forKey: CodingKeys.val)
                            try container.encodeIfPresent(str, forKey: CodingKeys.str)
                        case .multi(_: let variable,val: let val,let _2):
                            try _2.encode(to: encoder)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.val)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case variable = "variable"
                        case val = "val"
                        case str = "str"
                    }
                }
                """
        )
    }
    #endif

    func testUnTaggedEnumDecoding() throws {
        let data = try JSONDecoder().decode(
            CodableValue.self, from: heterogenousJSONData
        )
        switch data {
        case .array(let values):
            XCTAssertEqual(values.count, 7)
        default:
            XCTFail("Invalid data decoded")
        }
    }
}

@Codable
@UnTagged
enum CodableValue {
    case bool(Bool)
    case uint(UInt)
    case int(Int)
    case float(Float)
    case double(Double)
    case string(String)
    case array([Self])
    case dictionary([String: Self])
}

let heterogenousJSONData = """
    [
      true,
      12,
      -43,
      36.78,
      "test",
      [
        true,
        12,
        -43,
        36.78,
        "test",
        {
          "bool": true,
          "unit": 12,
          "int": -43,
          "float": 36.78,
          "string": "test",
          "array": [
            true,
            12,
            -43,
            36.78,
            "test"
          ],
          "dictionary": {
            "bool": true,
            "unit": 12,
            "int": -43,
            "float": 36.78,
            "string": "test",
            "array": [
              true,
              12,
              -43,
              36.78,
              "test"
            ]
          }
        }
      ],
      {
        "bool": true,
        "unit": 12,
        "int": -43,
        "float": 36.78,
        "string": "test",
        "array": [
          true,
          12,
          -43,
          36.78,
          "test",
          {
            "bool": true,
            "unit": 12,
            "int": -43,
            "float": 36.78,
            "string": "test",
            "array": [
              true,
              12,
              -43,
              36.78,
              "test"
            ],
            "dictionary": {
              "bool": true,
              "unit": 12,
              "int": -43,
              "float": 36.78,
              "string": "test",
              "array": [
                true,
                12,
                -43,
                36.78,
                "test"
              ]
            }
          }
        ],
        "dictionary": {
          "bool": true,
          "unit": 12,
          "int": -43,
          "float": 36.78,
          "string": "test",
          "array": [
            true,
            12,
            -43,
            36.78,
            "test"
          ],
          "dictionary": {
            "bool": true,
            "unit": 12,
            "int": -43,
            "float": 36.78,
            "string": "test",
            "array": [
              true,
              12,
              -43,
              36.78,
              "test"
            ]
          }
        }
      }
    ]
    """.data(using: .utf8)!
