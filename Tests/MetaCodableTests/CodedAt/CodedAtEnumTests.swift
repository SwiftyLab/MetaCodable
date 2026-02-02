import Foundation
import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

struct CodedAtEnumTests {
    @Test
    func misuseOnNonEnumDeclaration() throws {
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

    @Test
    func duplicatedMisuse() throws {
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
                                case "int":
                                    let val: Int
                                    val = try container.decode(Int.self, forKey: CodingKeys.val)
                                    self = .int(val: val)
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
                            try typeContainer.encode("int", forKey: CodingKeys.type)
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
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

    struct WithoutExplicitType {
        @Codable
        @CodedAt("type")
        enum Command {
            case load(key: String)
            case store(key: String, value: Int)
        }

        @Test
        func expansion() throws {
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
                                    case "load":
                                        let key: String
                                        key = try container.decode(String.self, forKey: CodingKeys.key)
                                        self = .load(key: key)
                                        return
                                    case "store":
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

                    extension Command: Encodable {
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

    struct WithExplicitType {
        @Codable
        @CodedAt("type")
        @CodedAs<Int>
        enum Command {
            @CodedAs(1)
            case load(key: String)
            @CodedAs(2)
            case store(key: String, value: Int)
        }

        @Test
        func expansion() throws {
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
                            var typeContainer: KeyedDecodingContainer<CodingKeys>
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            typeContainer = container
                            let type: Int
                            type = try typeContainer.decode(Int.self, forKey: CodingKeys.type)
                            switch type {
                            case 1:
                                let key: String
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case 2:
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
                                try typeContainer.encode(1, forKey: CodingKeys.type)
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
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
    }

    struct WithHelperExpression {
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

        @Test
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

    struct WithNestedOptionalIdentifier {
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

        @Test
        func expansion() throws {
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
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let data_container = ((try? container.decodeNil(forKey: CodingKeys.data)) == false) ? try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data) : nil
                            let attributes_data_container = ((try? data_container?.decodeNil(forKey: CodingKeys.attributes)) == false) ? try data_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes) : nil
                            if let _ = data_container {
                                if let attributes_data_container = attributes_data_container {
                                    typeContainer = attributes_data_container
                                } else {
                                    typeContainer = nil
                                }
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer {
                                let type: String?
                                type = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type)
                                switch type {
                                case "REGISTRATION":
                                    let _0: Registration
                                    _0 = try Registration(from: decoder)
                                    self = .registration(_0)
                                    return
                                case nil:
                                    let _0: Expiry
                                    _0 = try Expiry(from: decoder)
                                    self = .expiry(_0)
                                    return
                                default:
                                    break
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Operation: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var data_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.data)
                            let attributes_data_container = data_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                            var typeContainer = attributes_data_container
                            switch self {
                            case .registration(let _0):
                                try typeContainer.encode("REGISTRATION", forKey: CodingKeys.type)
                                try _0.encode(to: encoder)
                            case .expiry(let _0):
                                try typeContainer.encode(nil as String?, forKey: CodingKeys.type)
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

    struct WithOnlyAssociatedVariablesAtTopLevel {
        @Codable
        @CodedAt("type")
        enum TypeObject {
            case type1(Type1)

            @Codable
            struct Type1 {
                let int: Int
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                enum TypeObject {
                    case type1(Int)
                }
                """,
                expandedSource:
                    """
                    enum TypeObject {
                        case type1(Int)
                    }

                    extension TypeObject: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                typeContainer = container
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer {
                                let typeString: String?
                                do {
                                    typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeString = nil
                                }
                                if let typeString = typeString {
                                    switch typeString {
                                    case "type1":
                                        let _0: Int
                                        _0 = try Int(from: decoder)
                                        self = .type1(_0)
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

                    extension TypeObject: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            switch self {
                            case .type1(let _0):
                                try typeContainer.encode("type1", forKey: CodingKeys.type)
                                try _0.encode(to: encoder)
                            }
                        }
                    }

                    extension TypeObject {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                        }
                    }
                    """
            )
        }

        @Test
        func decodingAndEncoding() throws {
            let original = TypeObject.type1(TypeObject.Type1(int: 42))
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                TypeObject.self, from: encoded)
            if case .type1(let data) = decoded {
                #expect(data.int == 42)
            } else {
                Issue.record("Expected type1 case")
            }
        }

        @Test
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "type": "type1",
                    "int": 42
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                TypeObject.self, from: jsonData)
            if case .type1(let data) = decoded {
                #expect(data.int == 42)
            } else {
                Issue.record("Expected type1 case")
            }
        }

        @Test
        func encodingToJSON() throws {
            let original = TypeObject.type1(TypeObject.Type1(int: 42))
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["type"] as? String == "type1")
            #expect(json["int"] as? Int == 42)
        }
    }
}
