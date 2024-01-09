#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class ContentAtTests: XCTestCase {

    func testMisuseOnNonEnumDeclaration() throws {
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
                        "@ContentAt must be used in combination with @CodedAt",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ContentAt attribute")
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
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try container.decode(String.self, forKey: CodingKeys.type)
                        let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                        switch type {
                        case "load":
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case "store":
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: contentDecoder.codingPath,
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
                        let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                        switch self {
                        case .load(key: let key):
                            try typeContainer.encode("load", forKey: CodingKeys.type)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
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

    func testWithExplicitType() throws {
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
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let type = try container.decode(Int.self, forKey: CodingKeys.type)
                        let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                        switch type {
                        case 1:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case 2:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: contentDecoder.codingPath,
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
                        let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                        switch self {
                        case .load(key: let key):
                            try typeContainer.encode(1, forKey: CodingKeys.type)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
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

    func testWithHelperExpression() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            @ContentAt("content")
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
                        let contentDecoder = try container.superDecoder(forKey: CodingKeys.content)
                        switch type {
                        case [1, 2, 3]:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            self = .load(key: key)
                        case [4, 5, 6]:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let key = try container.decode(String.self, forKey: CodingKeys.key)
                            let value = try container.decode(Int.self, forKey: CodingKeys.value)
                            self = .store(key: key, value: value)
                        default:
                            let context = DecodingError.Context(
                                codingPath: contentDecoder.codingPath,
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
                        let contentEncoder = container.superEncoder(forKey: CodingKeys.content)
                        switch self {
                        case .load(key: let key):
                            try LossySequenceCoder<[Int]>().encode([1, 2, 3], to: &typeContainer, atKey: CodingKeys.type)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(key, forKey: CodingKeys.key)
                        case .store(key: let key,value: let value):
                            try LossySequenceCoder<[Int]>().encode([4, 5, 6], to: &typeContainer, atKey: CodingKeys.type)
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
#endif
