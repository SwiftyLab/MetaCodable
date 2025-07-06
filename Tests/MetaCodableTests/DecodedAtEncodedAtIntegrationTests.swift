import MetaCodable
import Testing
import Foundation
import HelperCoders

@testable import PluginCore

struct DecodedAtEncodedAtIntegrationTests {
    @Codable
    struct Person {
        let id: String
        @DecodedAt("personal_info", "name")
        @EncodedAt("full_name")
        let name: String
        @DecodedAt("personal_info", "years")
        @EncodedAt("age")
        let age: Int
    }

    @Test
    func differentPathsForDecodingAndEncoding() throws {
        // Sample JSON with nested structure for decoding
        let jsonData = """
        {
            "id": "12345",
            "personal_info": {
                "name": "John Doe",
                "years": 30
            }
        }
        """.data(using: .utf8)!

        // Decode the JSON
        let person = try JSONDecoder().decode(Person.self, from: jsonData)

        // Verify the decoded values
        #expect(person.id == "12345")
        #expect(person.name == "John Doe")
        #expect(person.age == 30)

        // Encode back to JSON
        let encodedData = try JSONEncoder().encode(person)
        let encodedJson = try JSONSerialization.jsonObject(with: encodedData) as! [String: Any]

        // Verify the encoded structure is different from the decoded one
        #expect(encodedJson["id"] as? String == "12345")
        #expect(encodedJson["full_name"] as? String == "John Doe") // Uses EncodedAt path
        #expect(encodedJson["age"] as? Int == 30) // Uses EncodedAt path
        #expect(encodedJson["personal_info"] == nil) // No nested structure in encoded JSON
    }

    @Codable
    struct NestedObject {
        @DecodedAt("data", "attributes", "name")
        @EncodedAt("name")
        let name: String

        @DecodedAt("data", "attributes", "value")
        @EncodedAt("attributes", "value")
        let value: Int

        @DecodedAt("meta", "created_at")
        @EncodedAt("createdAt")
        let createdAt: String
    }

    @Test
    func complexNestedStructure() throws {
        // Complex nested JSON for decoding
        let jsonData = """
        {
            "data": {
                "attributes": {
                    "name": "Test Object",
                    "value": 42
                }
            },
            "meta": {
                "created_at": "2025-07-05T12:00:00Z"
            }
        }
        """.data(using: .utf8)!

        // Decode the JSON
        let object = try JSONDecoder().decode(NestedObject.self, from: jsonData)

        // Verify the decoded values
        #expect(object.name == "Test Object")
        #expect(object.value == 42)
        #expect(object.createdAt == "2025-07-05T12:00:00Z")

        // Encode back to JSON
        let encodedData = try JSONEncoder().encode(object)
        let encodedJson = try JSONSerialization.jsonObject(with: encodedData) as! [String: Any]

        // Verify the encoded structure
        #expect(encodedJson["name"] as? String == "Test Object") // Top level
        #expect((encodedJson["attributes"] as? [String: Any])?["value"] as? Int == 42) // Nested under attributes
        #expect(encodedJson["createdAt"] as? String == "2025-07-05T12:00:00Z") // Top level
        #expect(encodedJson["data"] == nil) // Original nested structure is gone
        #expect(encodedJson["meta"] == nil) // Original nested structure is gone
    }

    @Codable
    struct OptionalValues {
        @DecodedAt("info", "name")
        @EncodedAt("name")
        let name: String?

        @DecodedAt("info", "value")
        @EncodedAt("value")
        let value: Int?
    }

    @Test
    func optionalValues() throws {
        // JSON with all values present
        let fullJsonData = """
        {
            "info": {
                "name": "Optional Test",
                "value": 100
            }
        }
        """.data(using: .utf8)!

        // JSON with missing values
        let partialJsonData = """
        {
            "info": {
                "name": "Optional Test"
            }
        }
        """.data(using: .utf8)!

        // Decode the full JSON
        let fullObject = try JSONDecoder().decode(OptionalValues.self, from: fullJsonData)
        #expect(fullObject.name == "Optional Test")
        #expect(fullObject.value == 100)

        // Decode the partial JSON
        let partialObject = try JSONDecoder().decode(OptionalValues.self, from: partialJsonData)
        #expect(partialObject.name == "Optional Test")
        #expect(partialObject.value == nil)

        // Encode full object back to JSON
        let fullEncodedData = try JSONEncoder().encode(fullObject)
        let fullEncodedJson = try JSONSerialization.jsonObject(with: fullEncodedData) as! [String: Any]

        // Verify the encoded structure
        #expect(fullEncodedJson["name"] as? String == "Optional Test")
        #expect(fullEncodedJson["value"] as? Int == 100)
        #expect(fullEncodedJson["info"] == nil)

        // Encode partial object back to JSON
        let partialEncodedData = try JSONEncoder().encode(partialObject)
        let partialEncodedJson = try JSONSerialization.jsonObject(with: partialEncodedData) as! [String: Any]

        // Verify the encoded structure
        #expect(partialEncodedJson["name"] as? String == "Optional Test")
        #expect(partialEncodedJson["value"] == nil)
        #expect(partialEncodedJson["info"] == nil)
    }

    struct EnumTests {
        @Test
        func misuseOnNonEnumDeclaration() throws {
            assertMacroExpansion(
                """
                @DecodedAt("type")
                @EncodedAt("inentifier")
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
                        id: DecodedAt.misuseID,
                        message:
                            "@DecodedAt must be used in combination with @Codable",
                        line: 1, column: 1,
                        fixIts: [
                            .init(message: "Remove @DecodedAt attribute")
                        ]
                    ),
                    .init(
                        id: EncodedAt.misuseID,
                        message:
                            "@EncodedAt must be used in combination with @Codable",
                        line: 2, column: 1,
                        fixIts: [
                            .init(message: "Remove @EncodedAt attribute")
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
                @DecodedAt("type1")
                @DecodedAt("type2")
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
                            case int = "int"
                            case string = "string"
                            case multi = "multi"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case bool = "bool"
                            case int = "int"
                            case string = "string"
                            case multi = "multi"
                        }
                    }
                    """,
                diagnostics: [
                    .init(
                        id: DecodedAt.misuseID,
                        message:
                            "@DecodedAt can only be applied once per declaration",
                        line: 2, column: 1,
                        fixIts: [
                            .init(message: "Remove @DecodedAt attribute")
                        ]
                    ),
                    .init(
                        id: DecodedAt.misuseID,
                        message:
                            "@DecodedAt must be used in combination with @EncodedAt",
                        line: 2, column: 1,
                        fixIts: [
                            .init(message: "Remove @DecodedAt attribute")
                        ]
                    ),
                    .init(
                        id: DecodedAt.misuseID,
                        message:
                            "@DecodedAt can only be applied once per declaration",
                        line: 3, column: 1,
                        fixIts: [
                            .init(message: "Remove @DecodedAt attribute")
                        ]
                    ),
                    .init(
                        id: DecodedAt.misuseID,
                        message:
                            "@DecodedAt must be used in combination with @EncodedAt",
                        line: 3, column: 1,
                        fixIts: [
                            .init(message: "Remove @DecodedAt attribute")
                        ]
                    ),
                ]
            )
        }

        struct WithoutExplicitType {
            @Codable
            @DecodedAt("type")
            @EncodedAt("inentifier")
            enum Command {
                case load(key: String)
                case store(key: String, value: Int)
            }

            @Test
            func expansion() throws {
                assertMacroExpansion(
                    """
                    @Codable
                    @DecodedAt("type")
                    @EncodedAt("inentifier")
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
                                    throw DecodingError.typeMismatch(Self.self, context)
                                }
                            }
                        }

                        extension Command: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                let container = encoder.container(keyedBy: CodingKeys.self)
                                var typeContainer = container
                                switch self {
                                case .load(key: let key):
                                    try typeContainer.encode("load", forKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                case .store(key: let key, value: let value):
                                    try typeContainer.encode("store", forKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                    try container.encode(value, forKey: CodingKeys.value)
                                }
                            }
                        }

                        extension Command {
                            enum CodingKeys: String, CodingKey {
                                case type = "type"
                                case inentifier = "inentifier"
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
            @DecodedAt("type")
            @EncodedAt("inentifier")
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
                    @DecodedAt("type")
                    @EncodedAt("inentifier")
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
                                    throw DecodingError.typeMismatch(Self.self, context)
                                }
                            }
                        }

                        extension Command: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                let container = encoder.container(keyedBy: CodingKeys.self)
                                var typeContainer = container
                                switch self {
                                case .load(key: let key):
                                    try typeContainer.encode(1, forKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                case .store(key: let key, value: let value):
                                    try typeContainer.encode(2, forKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                    try container.encode(value, forKey: CodingKeys.value)
                                }
                            }
                        }

                        extension Command {
                            enum CodingKeys: String, CodingKey {
                                case type = "type"
                                case inentifier = "inentifier"
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
            @DecodedAt("type")
            @EncodedAt("inentifier")
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
                    @DecodedAt("type")
                    @EncodedAt("inentifier")
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
                                let type: [Int]
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                type = try SequenceCoder(output: [Int].self, configuration: .lossy).decode(from: container, forKey: CodingKeys.type)
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
                                    throw DecodingError.typeMismatch(Self.self, context)
                                }
                            }
                        }

                        extension Command: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                let container = encoder.container(keyedBy: CodingKeys.self)
                                var typeContainer = container
                                switch self {
                                case .load(key: let key):
                                    try SequenceCoder(output: [Int].self, configuration: .lossy).encode([1, 2, 3], to: &typeContainer, atKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                case .store(key: let key, value: let value):
                                    try SequenceCoder(output: [Int].self, configuration: .lossy).encode([4, 5, 6], to: &typeContainer, atKey: CodingKeys.inentifier)
                                    var container = encoder.container(keyedBy: CodingKeys.self)
                                    try container.encode(key, forKey: CodingKeys.key)
                                    try container.encode(value, forKey: CodingKeys.value)
                                }
                            }
                        }

                        extension Command {
                            enum CodingKeys: String, CodingKey {
                                case type = "type"
                                case inentifier = "inentifier"
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
            @DecodedAt("data", "attributes", "operation")
            @EncodedAt("attributes", "operation")
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
                    @DecodedAt("data", "attributes", "operation")
                    @EncodedAt("attributes", "operation")
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
                                if let _ = data_container {
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
                                case nil:
                                    let _0: Expiry
                                    _0 = try Expiry(from: decoder)
                                    self = .expiry(_0)
                                default:
                                    let context = DecodingError.Context(
                                        codingPath: decoder.codingPath,
                                        debugDescription: "Couldn't match any cases."
                                    )
                                    throw DecodingError.typeMismatch(Self.self, context)
                                }
                            }
                        }

                        extension Operation: Encodable {
                            func encode(to encoder: any Encoder) throws {
                                var container = encoder.container(keyedBy: CodingKeys.self)
                                let attributes_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.attributes)
                                var typeContainer = attributes_container
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
    }
}
