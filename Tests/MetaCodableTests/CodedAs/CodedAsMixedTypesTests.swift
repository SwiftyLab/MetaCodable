import Foundation
import MetaCodable
import Testing

@testable import PluginCore

/// Tests for `@CodedAs` macro with mixed literal types including partial `Bool` coverage.
///
/// These tests verify that internally tagged enums work correctly when `@CodedAs`
/// specifies multiple literal types (`String`, `Int`, `Bool`) and not all `enum` cases
/// have `Bool` values, resulting in partial `Bool` coverage in `switch` statements.
@Suite("CodedAs Mixed Types Tests")
struct CodedAsMixedTypesTests {
    /// Tests macro expansion when `@CodedAs` includes `Bool` values
    /// but not all cases have them.
    ///
    /// This scenario requires the generated `Bool` switch to include a `default` case
    /// since only `true` is specified (for `load` case) and `false` is not covered.
    @Test("Expansion with partial Bool coverage")
    func expansionWithPartialBoolCoverage() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            enum Command {
                @CodedAs("load", 12, true)
                case load(key: String)
                @CodedAs("store", 30)
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
                        let typeBool: Bool?
                        do {
                            typeBool = try typeContainer.decodeIfPresent(Bool.self, forKey: CodingKeys.type) ?? nil
                        } catch {
                            typeBool = nil
                        }
                        if let typeBool = typeBool {
                            switch typeBool {
                            case true:
                                let key: String
                                let container = try decoder.container(keyedBy: CodingKeys.self)
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            default:
                                break
                            }
                        }
                        let typeInt: Int?
                        do {
                            typeInt = try typeContainer.decodeIfPresent(Int.self, forKey: CodingKeys.type) ?? nil
                        } catch {
                            typeInt = nil
                        }
                        if let typeInt = typeInt {
                            switch typeInt {
                            case 12:
                                let key: String
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case 30:
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

    /// Tests macro expansion when only `false` is specified for Bool type.
    ///
    /// Similar to the `true`-only case, this requires a `default` case since
    /// `true` is not covered.
    @Test("Expansion with only false Bool value")
    func expansionWithOnlyFalseBoolValue() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodedAt("type")
            enum Command {
                @CodedAs("load", 12)
                case load(key: String)
                @CodedAs("store", 30, false)
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
                        let typeBool: Bool?
                        do {
                            typeBool = try typeContainer.decodeIfPresent(Bool.self, forKey: CodingKeys.type) ?? nil
                        } catch {
                            typeBool = nil
                        }
                        if let typeBool = typeBool {
                            switch typeBool {
                            case false:
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
                        }
                        let typeInt: Int?
                        do {
                            typeInt = try typeContainer.decodeIfPresent(Int.self, forKey: CodingKeys.type) ?? nil
                        } catch {
                            typeInt = nil
                        }
                        if let typeInt = typeInt {
                            switch typeInt {
                            case 12:
                                let key: String
                                key = try container.decode(String.self, forKey: CodingKeys.key)
                                self = .load(key: key)
                                return
                            case 30:
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
