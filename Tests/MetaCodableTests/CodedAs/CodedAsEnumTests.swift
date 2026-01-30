import HelperCoders
import MetaCodable
import SwiftDiagnostics
import Testing

@testable import PluginCore

@Suite("Coded As Enum Tests")
struct CodedAsEnumTests {
    @Test("Reports error for @CodedAs misuse")
    func misuseOnNonCaseDeclaration() throws {
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

    @Test("Reports error for @Codable misuse (CodedAsEnumTests #2)")
    func invalidRangeExpressionTypeDiagnostic() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            enum SomeEnum {
                @CodedAs("load", true...false)
                case load(key: String)
                @CodedAs("store", 1..."end")
                case store(key: String, value: Int)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case load(key: String)
                    case store(key: String, value: Int)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        var typeContainer: KeyedDecodingContainer<CodingKeys>?
                        let container = try? decoder.container(keyedBy: CodingKeys.self)
                        if let container = container {
                            typeContainer = container
                        } else {
                            typeContainer = nil
                        }
                        if let typeContainer = typeContainer, let container = container {
                            let typeString: String?
                            do {
                                typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                            } catch {
                                typeString = nil
                            }
                            if let typeString = typeString {
                                switch typeString {
                                case "load", true ... false:
                                    let key: String
                                    key = try container.decode(String.self, forKey: CodingKeys.key)
                                    self = .load(key: key)
                                    return
                                case "store", 1 ... "end":
                                    let key: String
                                    let value: Int
                                    key = try container.decode(String.self, forKey: CodingKeys.key)
                                    value = try container.decode(Int.self, forKey: CodingKeys.value)
                                    self = .store(key: key, value: value)
                                    return
                                default:
                                    break
                                }
                            }
                        }
                        let context = DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Couldn't match any cases."
                        )
                        throw DecodingError.typeMismatch(Self.self, context)
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        let container = encoder.container(keyedBy: CodingKeys.self)
                        var typeContainer = container
                        switch self {
                        case .load(key: let key):
                            try typeContainer.encode("load", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key, value: let value):
                            try typeContainer.encode("store", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                            try container.encode(value, forKey: CodingKeys.value)
                        }
                    }
                }

                extension SomeEnum {
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
                    message: "Invalid expression type for enum case value",
                    line: 4, column: 22,
                    fixIts: []
                ),
                .init(
                    id: CodedAs.misuseID,
                    message: "Invalid expression type for enum case value",
                    line: 6, column: 23,
                    fixIts: []
                ),
                .init(
                    id: CodedAs.misuseID,
                    message: "Invalid expression type for enum case value",
                    line: 4, column: 22,
                    fixIts: []
                ),
                .init(
                    id: CodedAs.misuseID,
                    message: "Invalid expression type for enum case value",
                    line: 6, column: 23,
                    fixIts: []
                ),
            ]
        )
    }

    @Test("Reports error when @CodedAs is applied multiple times")
    func duplicatedMisuse() throws {
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

    @Test("Reports error for @CodedAs misuse (CodedAsEnumTests #1)")
    func misuseInCombinationWithIgnoreCodingMacro() throws {
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

    @Test("Reports error for @Codable misuse (CodedAsEnumTests #3)")
    func misuseOnNonEnumDeclaration() throws {
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
                        "@CodedAs must be used in combination with @CodedAt, @DecodedAt or @EncodedAt",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @CodedAs attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Coded As Enum - CodedBy")
    struct WithCodedByMacro {
        @Codable
        @CodedAt("type")
        @CodedAs<[Int]>
        @CodedBy(SequenceCoder(output: [Int].self, configuration: .lossy))
        enum Command {
            @CodedAs([1, 2, 3])
            case load(key: String)
            @CodedAs([4, 5, 6])
            case store(key: String, value: Int)
        }

        @Test("Generates macro expansion with @Codable for enum (CodedAsEnumTests #1)")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                @CodedAs<[Int]>
                @CodedBy(SequenceCoder(output: [Int].self, configuration: .lossy))
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
                            var typeContainer: KeyedDecodingContainer<CodingKeys>
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            typeContainer = container
                            let type: [Int]
                            type = try SequenceCoder(output: [Int].self, configuration: .lossy).decode(from: typeContainer, forKey: CodingKeys.type)
                            switch type {
                            case [1, 2, 3]:
                                let key: String
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case [4, 5, 6]:
                                let key: String
                                let value: Int
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                value = try container.decode(Int.self, forKey: CodingKeys.value)
                                self = .store(key: key, value: value)
                                return
                            default:
                                break
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Command: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            switch self {
                            case .load(key: let key):
                                try SequenceCoder(output: [Int].self, configuration: .lossy).encode([1, 2, 3], to: &typeContainer, atKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
                                try SequenceCoder(output: [Int].self, configuration: .lossy).encode([4, 5, 6], to: &typeContainer, atKey: CodingKeys.type)
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

    @Suite("Coded As Enum - Externally Tagged Custom Value")
    struct ExternallyTaggedCustomValue {
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

        @Test("Generates macro expansion with @Codable for enum (CodedAsEnumTests #2)")
        func expansion() throws {
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
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variable: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                self = .bool(_: variable)
                            case DecodingKeys.int:
                                let val: Int
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                self = .int(val: val)
                            case DecodingKeys.double, DecodingKeys.altDouble2:
                                let _0: Double
                                _0 = try Double(from: contentDecoder)
                                self = .double(_: _0)
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
                            case .multi(_: let variable, val: let val, let _2):
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
    }

    @Suite("Coded As Enum - Internally Tagged Custom Value")
    struct InternallyTaggedCustomValue {
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

        @Test("Generates macro expansion with @Codable for enum (CodedAsEnumTests #3)")
        func expansion() throws {
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
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                typeContainer = container
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer, let container = container {
                                let typeString: String?
                                do {
                                    typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeString = nil
                                }
                                if let typeString = typeString {
                                    switch typeString {
                                    case "bool":
                                        let variable: Bool
                                        variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                        self = .bool(_: variable)
                                        return
                                    case "altInt":
                                        let val: Int
                                        val = try container.decode(Int.self, forKey: CodingKeys.val)
                                        self = .int(val: val)
                                        return
                                    case "altDouble1", "altDouble2":
                                        let _0: Double
                                        _0 = try Double(from: decoder)
                                        self = .double(_: _0)
                                        return
                                    case "string":
                                        let _0: String
                                        _0 = try String(from: decoder)
                                        self = .string(_0)
                                        return
                                    case "multi":
                                        let variable: Bool
                                        let val: Int
                                        let _2: String
                                        _2 = try String(from: decoder)
                                        variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                        val = try container.decode(Int.self, forKey: CodingKeys.val)
                                        self = .multi(_: variable, val: val, _2)
                                        return
                                    default:
                                        break
                                    }
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension SomeEnum: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
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
                            case .multi(_: let variable, val: let val, let _2):
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
}
