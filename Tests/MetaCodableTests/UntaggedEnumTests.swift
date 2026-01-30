import Foundation
import MetaCodable
import Testing
import XCTest

@testable import PluginCore

@Suite("Untagged Enum Tests")
struct UntaggedEnumTests {
    @Test("Reports error for @Codable misuse (UntaggedEnumTests #7)", .tags(.codable, .decoding, .encoding, .enums, .errorHandling, .macroExpansion, .structs, .untagged))
    func misuseOnNonEnumDeclaration() throws {
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

    @Test("Reports error for @Codable misuse (UntaggedEnumTests #8)", .tags(.codable, .codedAt, .encoding, .enums, .errorHandling, .macroExpansion, .untagged))
    func misuseInCombinationWithCodedAtMacro() throws {
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
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(Self.self, context)
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

    @Test("Reports error for @Codable misuse (UntaggedEnumTests #9)", .tags(.codable, .encoding, .enums, .errorHandling, .macroExpansion, .untagged))
    func duplicatedMisuse() throws {
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
                        let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(Self.self, context)
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

    @Suite("Untagged Enum - Without Fallback Case")
    struct WithoutFallbackCase {
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

        @Test("Generates macro expansion with @Codable for enum (UntaggedEnumTests #28)", .tags(.codable, .encoding, .enums, .macroExpansion, .untagged))
        func expansion() throws {
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
                            let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(Self.self, context)
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
                                                        _0 = try [Self](from: decoder)
                                                        self = .array(_0)
                                                        return
                                                    } catch {
                                                        let _0: [String: Self]
                                                        do {
                                                            _0 = try [String: Self](from: decoder)
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

        @Test("Encodes and decodes successfully (UntaggedEnumTests #36)", .tags(.decoding, .encoding, .untagged))
        func decodingAndEncodingBool() throws {
            let original: CodableValue = .bool(true)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                CodableValue.self, from: encoded)
            if case .bool(let value) = decoded {
                #expect(value == true)
            } else {
                Issue.record("Expected .bool case")
            }
        }

        @Test("Encodes and decodes successfully (UntaggedEnumTests #37)", .tags(.decoding, .encoding, .untagged))
        func decodingAndEncodingString() throws {
            let original: CodableValue = .string("test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                CodableValue.self, from: encoded)
            if case .string(let value) = decoded {
                #expect(value == "test")
            } else {
                Issue.record("Expected .string case")
            }
        }

        @Test("Decodes from JSON successfully (UntaggedEnumTests #98)", .tags(.decoding, .untagged))
        func decodingFromJSONPrimitives() throws {
            // Test bool
            let boolJson = "true".data(using: .utf8)!
            let boolDecoded = try JSONDecoder().decode(
                CodableValue.self, from: boolJson)
            if case .bool(let value) = boolDecoded {
                #expect(value == true)
            } else {
                Issue.record("Expected .bool case for true")
            }

            // Test string
            let stringJson = "\"hello\"".data(using: .utf8)!
            let stringDecoded = try JSONDecoder().decode(
                CodableValue.self, from: stringJson)
            if case .string(let value) = stringDecoded {
                #expect(value == "hello")
            } else {
                Issue.record("Expected .string case for hello")
            }

            // Test uint (42 will be decoded as uint since it comes before int in case order)
            let uintJson = "42".data(using: .utf8)!
            let uintDecoded = try JSONDecoder().decode(
                CodableValue.self, from: uintJson)
            if case .uint(let value) = uintDecoded {
                #expect(value == 42)
            } else {
                Issue.record("Expected .uint case for 42")
            }
        }

        @Test("Decodes from JSON successfully (UntaggedEnumTests #99)", .tags(.decoding, .untagged))
        func decodingFromJSONArray() throws {
            let arrayJson = "[true, \"test\", 123]".data(using: .utf8)!
            let arrayDecoded = try JSONDecoder().decode(
                CodableValue.self, from: arrayJson)
            if case .array(let values) = arrayDecoded {
                #expect(values.count == 3)
                if case .bool(let boolVal) = values[0] {
                    #expect(boolVal == true)
                } else {
                    Issue.record("Expected first element to be bool")
                }
            } else {
                Issue.record("Expected .array case")
            }
        }
    }

    @Suite("Untagged Enum - With Fallback Case")
    struct WithFallbackCase {
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

        @Test("Generates macro expansion with @Codable for enum (UntaggedEnumTests #29)", .tags(.codable, .encoding, .enums, .macroExpansion, .untagged))
        func expansion() throws {
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
                                                        _0 = try [Self](from: decoder)
                                                        self = .array(_0)
                                                        return
                                                    } catch {
                                                        let _0: [String: Self]
                                                        do {
                                                            _0 = try [String: Self](from: decoder)
                                                            self = .dictionary(_0)
                                                            return
                                                        } catch {
                                                            self = .`nil`
                                                            return
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

        @Test("Decodes from JSON successfully (UntaggedEnumTests #100)", .tags(.decoding, .untagged))
        func decoding() throws {
            let data = try JSONDecoder().decode(
                CodableValue.self, from: heterogenousJSONData
            )
            switch data {
            case .array(let values):
                #expect(values.count == 7)
            default:
                Issue.record("Invalid data decoded")
            }
        }
    }

    @Suite("Untagged Enum - Nested Decoding")
    struct NestedDecoding {
        @Codable
        @UnTagged
        enum SomeEnum {
            case bool(_ variable: Bool)
            case int(val: Int)
            case string(String)
            case multiOpt(_ variable: Bool?, val: Int?, str: String?)
            case multi(_ variable: Bool, val: Int, String)
        }

        @Test("Generates macro expansion with @Codable for enum (UntaggedEnumTests #30)", .tags(.codable, .decoding, .encoding, .enums, .macroExpansion, .optionals, .untagged))
        func expansion() throws {
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
                            let __macro_local_13decodingErrorfMu0_ =  DecodingError.typeMismatch(Self.self, context)
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
                                                _2 = try String(from: decoder)
                                                if let container = container {
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
                            case .multiOpt(_: let variable, val: let val, str: let str):
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encodeIfPresent(variable, forKey: CodingKeys.variable)
                                try container.encodeIfPresent(val, forKey: CodingKeys.val)
                                try container.encodeIfPresent(str, forKey: CodingKeys.str)
                            case .multi(_: let variable, val: let val, let _2):
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
    }
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
