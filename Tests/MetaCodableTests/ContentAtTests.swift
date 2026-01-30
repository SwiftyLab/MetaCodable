import Foundation
import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Content At Tests")
struct ContentAtTests {
    @Test("Reports error when @ContentAt is used without @Codable")
    func misuseOnNonEnumDeclaration() throws {
        assertMacroExpansion(
            """
            @ContentAt("content")
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
                """,
            diagnostics: [
                .init(
                    id: ContentAt.misuseID,
                    message:
                        "@ContentAt must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ContentAt attribute")
                    ]
                ),
                .init(
                    id: ContentAt.misuseID,
                    message:
                        "@ContentAt must be used in combination with @CodedAt, @DecodedAt or @EncodedAt",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ContentAt attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Content At - Without Explicit Type")
    struct WithoutExplicitType {
        @Codable
        @CodedAt("type")
        @ContentAt("content")
        enum Command {
            case load(key: String)
            case store(key: String, value: Int)
        }

        @Test("Generates macro expansion with @Codable for enum (ContentAtTests #10)")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                @ContentAt("content")
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
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            typeContainer = container
                            let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                            if let typeContainer = typeContainer {
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
                                codingPath: contentDecoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Command: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                            switch self {
                            case .load(key: let key):
                                try typeContainer.encode("load", forKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
                                try typeContainer.encode("store", forKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                                try container.encode(value, forKey: CodingKeys.value)
                            }
                        }
                    }

                    extension Command {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                            case content = "content"
                            case key = "key"
                            case value = "value"
                        }
                    }
                    """
            )
        }

        @Test("Encodes to JSON successfully (ContentAtTests #10)")
        func contentAtEncodingStructure() throws {
            let loadCommand: Command = .load(key: "test_key")
            let encoded = try JSONEncoder().encode(loadCommand)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]

            #expect(json["type"] as? String == "load")
            let content = json["content"] as! [String: Any]
            #expect(content["key"] as? String == "test_key")
        }

        @Test("Decodes from JSON successfully (ContentAtTests #40)")
        func contentAtFromJSON() throws {
            // The decoding expects key/value at root level, not in content
            let jsonStr = """
                {
                    "type": "store",
                    "key": "my_key",
                    "value": 42
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Command.self, from: jsonData)

            if case .store(let key, let value) = decoded {
                #expect(key == "my_key")
                #expect(value == 42)
            } else {
                Issue.record("Expected .store case")
            }
        }

        @Test("Encodes to JSON successfully (ContentAtTests #11)")
        func contentAtJSONStructure() throws {
            let storeCommand: Command = .store(key: "test", value: 100)
            let encoded = try JSONEncoder().encode(storeCommand)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]

            #expect(json["type"] as? String == "store")
            let content = json["content"] as! [String: Any]
            #expect(content["key"] as? String == "test")
            #expect(content["value"] as? Int == 100)
        }
    }

    @Suite("Content At - Explicit")
    struct WithExplicitType {
        @Codable
        @CodedAt("type")
        @ContentAt("content")
        @CodedAs<Int>
        enum Command {
            @CodedAs(1)
            case load(key: String)
            @CodedAs(2)
            case store(key: String, value: Int)
        }

        @Test("Generates macro expansion with @Codable for enum (ContentAtTests #11)")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                @ContentAt("content")
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
                            let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                            let type: Int
                            type = try typeContainer.decode(Int.self, forKey: CodingKeys.type)
                            switch type {
                            case 1:
                                let key: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case 2:
                                let key: String
                                let value: Int
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                value = try container.decode(Int.self, forKey: CodingKeys.value)
                                self = .store(key: key, value: value)
                                return
                            default:
                                break
                            }
                            let context = DecodingError.Context(
                                codingPath: contentDecoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Command: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                            switch self {
                            case .load(key: let key):
                                try typeContainer.encode(1, forKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
                                try typeContainer.encode(2, forKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                                try container.encode(value, forKey: CodingKeys.value)
                            }
                        }
                    }

                    extension Command {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                            case content = "content"
                            case key = "key"
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Content At - With Helper Expression")
    struct WithHelperExpression {
        @Codable
        @CodedAt("type")
        @ContentAt("content")
        @CodedAs<[Int]>()
        @CodedBy(SequenceCoder(output: [Int].self, configuration: .lossy))
        enum Command {
            @CodedAs([1, 2, 3])
            case load(key: String)
            @CodedAs([4, 5, 6])
            case store(key: String, value: Int)
        }

        @Test("Generates macro expansion with @Codable for enum (ContentAtTests #12)")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("type")
                @ContentAt("content")
                @CodedAs<[Int]>()
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
                            let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                            let type: [Int]
                            type = try SequenceCoder(output: [Int].self, configuration: .lossy).decode(from: typeContainer, forKey: CodingKeys.type)
                            switch type {
                            case [1, 2, 3]:
                                let key: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case [4, 5, 6]:
                                let key: String
                                let value: Int
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                value = try container.decode(Int.self, forKey: CodingKeys.value)
                                self = .store(key: key, value: value)
                                return
                            default:
                                break
                            }
                            let context = DecodingError.Context(
                                codingPath: contentDecoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Command: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                            switch self {
                            case .load(key: let key):
                                try SequenceCoder(output: [Int].self, configuration: .lossy).encode([1, 2, 3], to: &typeContainer, atKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                            case .store(key: let key, value: let value):
                                try SequenceCoder(output: [Int].self, configuration: .lossy).encode([4, 5, 6], to: &typeContainer, atKey: CodingKeys.type)
                                var container = contentEncoder.container(keyedBy: CodingKeys.self)
                                try container.encode(key, forKey: CodingKeys.key)
                                try container.encode(value, forKey: CodingKeys.value)
                            }
                        }
                    }

                    extension Command {
                        enum CodingKeys: String, CodingKey {
                            case type = "type"
                            case content = "content"
                            case key = "key"
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }
}
