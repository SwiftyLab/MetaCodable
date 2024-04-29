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
                        let type: String
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        type = try container.decode(String.self, forKey: CodingKeys.type)
                        switch type {
                        case "bool":
                            let variable: Bool
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            self = .bool(_: variable)
                        case "int":
                            let val: Int
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case "string":
                            let _0: String
                            _0 = try String(from: decoder)
                            self = .string(_0)
                        case "multi":
                            let variable: Bool
                            let val: Int
                            let _2: String
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            _2 = try String(from: decoder)
                            variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            val = try container.decode(Int.self, forKey: CodingKeys.val)
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
                        let type: String
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        type = try container.decode(String.self, forKey: CodingKeys.type)
                        switch type {
                        case "load":
                            let key: String
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case "store":
                            let key: String
                            let value: Int
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            value = try container.decode(Int.self, forKey: CodingKeys.value)
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
                        let type: Int
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        type = try container.decode(Int.self, forKey: CodingKeys.type)
                        switch type {
                        case 1:
                            let key: String
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case 2:
                            let key: String
                            let value: Int
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            value = try container.decode(Int.self, forKey: CodingKeys.value)
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
                        let type: String
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        type = try LossySequenceCoder<[Int]>().decode(from: container, forKey: CodingKeys.type)
                        switch type {
                        case [1, 2, 3]:
                            let key: String
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case [4, 5, 6]:
                            let key: String
                            let value: Int
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            key = try container.decode(String.self, forKey: CodingKeys.key)
                            value = try container.decode(Int.self, forKey: CodingKeys.value)
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

    func testWithNestedOptionalIdentifier() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAs<String?>
            @CodedAt("data", "attributes", "operation")
            enum Operation {
                @CodedAs("REGISTRATION")
                case registration(Registration)
                @CodedAs(nil as String?)
                case expiry(Expiry)

                @Codable
                struct Registration {
                    @CodedIn("data", "attributes")
                    let mac: String
                    @CodedIn("data", "attributes")
                    let challange: String
                    @CodedIn("data", "attributes")
                    let code: Int
                }

                @Codable
                struct Expiry {
                    @CodedIn("data", "attributes")
                    let token: String
                    @CodedIn("data", "attributes")
                    let expiresIn: Double
                }
            }
            """,
            expandedSource:
                """
                enum Operation {
                    case registration(Registration)
                    case expiry(Expiry)
                    struct Registration {
                        let mac: String
                        let challange: String
                        let code: Int
                    }
                    struct Expiry {
                        let token: String
                        let expiresIn: Double
                    }
                }

                extension Operation.Registration: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let data_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                        let attributes_data_container = try data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                        self.mac = try attributes_data_container.decode(String.self, forKey: CodingKeys.mac)
                        self.challange = try attributes_data_container.decode(String.self, forKey: CodingKeys.challange)
                        self.code = try attributes_data_container.decode(Int.self, forKey: CodingKeys.code)
                    }
                }

                extension Operation.Registration: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var data_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                        var attributes_data_container = data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                        try attributes_data_container.encode(self.mac, forKey: CodingKeys.mac)
                        try attributes_data_container.encode(self.challange, forKey: CodingKeys.challange)
                        try attributes_data_container.encode(self.code, forKey: CodingKeys.code)
                    }
                }

                extension Operation.Registration {
                    enum CodingKeys: String, CodingKey {
                        case mac = "mac"
                        case data = "data"
                        case attributes = "attributes"
                        case challange = "challange"
                        case code = "code"
                    }
                }

                extension Operation.Expiry: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let data_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                        let attributes_data_container = try data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                        self.token = try attributes_data_container.decode(String.self, forKey: CodingKeys.token)
                        self.expiresIn = try attributes_data_container.decode(Double.self, forKey: CodingKeys.expiresIn)
                    }
                }

                extension Operation.Expiry: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var data_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                        var attributes_data_container = data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                        try attributes_data_container.encode(self.token, forKey: CodingKeys.token)
                        try attributes_data_container.encode(self.expiresIn, forKey: CodingKeys.expiresIn)
                    }
                }

                extension Operation.Expiry {
                    enum CodingKeys: String, CodingKey {
                        case token = "token"
                        case data = "data"
                        case attributes = "attributes"
                        case expiresIn = "expiresIn"
                    }
                }

                extension Operation: Decodable {
                    init(from decoder: any Decoder) throws {
                        let type: String?
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let data_container = ((try? container.decodeNil(forKey: CodingKeys.data)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data) : nil
                        let attributes_data_container = ((try? data_container?.decodeNil(forKey: CodingKeys.attributes)) == false) ? try data_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes) : nil
                        if let data_container = data_container {
                            if let attributes_data_container = attributes_data_container {
                                type = try attributes_data_container.decodeIfPresent(String.self, forKey: CodingKeys.type)
                            } else {
                                type = nil
                            }
                        } else {
                            type = nil
                        }
                        switch type {
                        case "REGISTRATION":
                            let _0: Registration
                            _0 = try Registration(from: decoder)
                            self = .registration(_0)
                        case nil as String?:
                            let _0: Expiry
                            _0 = try Expiry(from: decoder)
                            self = .expiry(_0)
                        default:
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Operation.self, context)
                        }
                    }
                }

                extension Operation: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        var data_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                        var attributes_data_container = data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                        var typeContainer = attributes_data_container
                        switch self {
                        case .registration(let _0):
                            try typeContainer.encodeIfPresent("REGISTRATION", forKey: CodingKeys.type)
                            try _0.encode(to: encoder)
                        case .expiry(let _0):
                            try typeContainer.encodeIfPresent(nil as String?, forKey: CodingKeys.type)
                            try _0.encode(to: encoder)
                        }
                    }
                }

                extension Operation {
                    enum CodingKeys: String, CodingKey {
                        case type = "operation"
                        case data = "data"
                        case attributes = "attributes"
                    }
                }
                """
        )
    }
}
#endif
