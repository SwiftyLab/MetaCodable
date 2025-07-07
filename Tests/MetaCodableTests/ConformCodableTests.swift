import Foundation
import HelperCoders
import MetaCodable
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import PluginCore

struct ConformEncodableTests {
    @Test
    func misuseWithCodable() throws {
        assertMacroExpansion(
            """
            @ConformEncodable
            @Codable
            struct SomeEncodable {
                let value: String
                let count: Int
            }
            """,
            expandedSource:
                """
                struct SomeEncodable {
                    let value: String
                    let count: Int
                }
                """,
            diagnostics: [
                .init(
                    id: ConformEncodable.misuseID,
                    message:
                        "@ConformEncodable can't be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformEncodable attribute")
                    ]
                ),
                .init(
                    id: ConformEncodable.misuseID,
                    message:
                        "@ConformEncodable can't be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformEncodable attribute")
                    ]
                ),
                .init(
                    id: Codable.misuseID,
                    message:
                        "@Codable can't be used in combination with @ConformEncodable",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @Codable attribute")
                    ]
                ),
            ]
        )
    }

    @Test
    func misuseWithDecodable() throws {
        assertMacroExpansion(
            """
            @ConformEncodable
            @ConformDecodable
            struct SomeEncodable {
                let value: String
                let count: Int
            }
            """,
            expandedSource:
                """
                struct SomeEncodable {
                    let value: String
                    let count: Int
                }
                """,
            diagnostics: [
                .init(
                    id: ConformEncodable.misuseID,
                    message:
                        "@ConformEncodable can't be used in combination with @ConformDecodable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformEncodable attribute")
                    ]
                ),
                .init(
                    id: ConformDecodable.misuseID,
                    message:
                        "@ConformDecodable can't be used in combination with @ConformEncodable",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformDecodable attribute")
                    ]
                ),
                .init(
                    id: ConformEncodable.misuseID,
                    message:
                        "@ConformEncodable can't be used in combination with @ConformDecodable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformEncodable attribute")
                    ]
                ),
                .init(
                    id: ConformDecodable.misuseID,
                    message:
                        "@ConformDecodable can't be used in combination with @ConformEncodable",
                    line: 2, column: 1,
                    fixIts: [
                        .init(message: "Remove @ConformDecodable attribute")
                    ]
                ),
            ]
        )
    }

    struct WithoutCommonStrategies {
        @ConformEncodable
        struct SomeEncodable {
            let value: String
            let count: Int
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformEncodable
                struct SomeEncodable {
                    let value: String
                    let count: Int
                }
                """,
                expandedSource:
                    """
                    struct SomeEncodable {
                        let value: String
                        let count: Int
                    }

                    extension SomeEncodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try container.encode(self.count, forKey: CodingKeys.count)
                        }
                    }

                    extension SomeEncodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case count = "count"
                        }
                    }
                    """
            )
        }
    }

    struct WithCommonStrategies {
        @ConformEncodable(commonStrategies: [.codedBy(.valueCoder())])
        struct Model {
            let bool: Bool
            let int: Int
            let double: Double
            let string: String
        }

        @Test
        func testParsing() throws {
            let model = Model(
                bool: true, int: 42, double: 3.1416, string: "5265762156")

            #expect(model.bool)
            #expect(model.int == 42)
            #expect(model.double == 3.1416)
            #expect(model.string == "5265762156")

            // Test that encoding works too
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try encoder.encode(model)
            let reDecoded = try #require(
                JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            #expect(reDecoded["bool"] as? Bool ?? false)
            #expect(reDecoded["int"] as? Int == 42)
            #expect(reDecoded["double"] as? Double == 3.1416)
            #expect(reDecoded["string"] as? String == "5265762156")
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformEncodable(commonStrategies: [.codedBy(.valueCoder())])
                struct Model {
                    let bool: Bool
                    let int: Int
                    let double: Double
                    let string: String
                }
                """,
                expandedSource:
                    """
                    struct Model {
                        let bool: Bool
                        let int: Int
                        let double: Double
                        let string: String
                    }

                    extension Model: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try ValueCoder<Bool>().encode(self.bool, to: &container, atKey: CodingKeys.bool)
                            try ValueCoder<Int>().encode(self.int, to: &container, atKey: CodingKeys.int)
                            try ValueCoder<Double>().encode(self.double, to: &container, atKey: CodingKeys.double)
                            try ValueCoder<String>().encode(self.string, to: &container, atKey: CodingKeys.string)
                        }
                    }

                    extension Model {
                        enum CodingKeys: String, CodingKey {
                            case bool = "bool"
                            case int = "int"
                            case double = "double"
                            case string = "string"
                        }
                    }
                    """
            )
        }
    }

    struct WithCustomCodingKeys {
        @ConformEncodable
        struct SomeEncodable {
            @CodedAt("custom_value")
            let value: String

            @CodedIn("nested", "path")
            let count: Int
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformEncodable
                struct SomeEncodable {
                    @CodedAt("custom_value")
                    let value: String
                    @CodedIn("nested", "path")
                    let count: Int
                }
                """,
                expandedSource:
                    """
                    struct SomeEncodable {
                        let value: String
                        let count: Int
                    }

                    extension SomeEncodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            var nested_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            var path_nested_container = nested_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.path)
                            try path_nested_container.encode(self.count, forKey: CodingKeys.count)
                        }
                    }

                    extension SomeEncodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "custom_value"
                            case count = "count"
                            case nested = "nested"
                            case path = "path"
                        }
                    }
                    """
            )
        }
    }
}

struct ConformDecodableTests {
    struct WithoutCommonStrategies {
        @ConformDecodable
        struct SomeDecodable {
            let value: String
            let count: Int
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformDecodable
                struct SomeDecodable {
                    let value: String
                    let count: Int
                }
                """,
                expandedSource:
                    """
                    struct SomeDecodable {
                        let value: String
                        let count: Int
                    }

                    extension SomeDecodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            self.count = try container.decode(Int.self, forKey: CodingKeys.count)
                        }
                    }

                    extension SomeDecodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case count = "count"
                        }
                    }
                    """
            )
        }
    }

    struct WithCommonStrategies {
        @ConformDecodable(commonStrategies: [.codedBy(.valueCoder())])
        struct Model {
            let bool: Bool
            let int: Int
            let double: Double
            let string: String
        }

        @Test
        func testParsing() throws {
            let json = """
                {
                    "bool": "true",
                    "int": "42",
                    "double": "3.1416",
                    "string": 5265762156
                }
                """

            let jsonData = try #require(json.data(using: .utf8))
            let decoder = JSONDecoder()
            let model = try decoder.decode(Model.self, from: jsonData)

            #expect(model.bool)
            #expect(model.int == 42)
            #expect(model.double == 3.1416)
            #expect(model.string == "5265762156")
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformDecodable(commonStrategies: [.codedBy(.valueCoder())])
                struct Model {
                    let bool: Bool
                    let int: Int
                    let double: Double
                    let string: String
                }
                """,
                expandedSource:
                    """
                    struct Model {
                        let bool: Bool
                        let int: Int
                        let double: Double
                        let string: String
                    }

                    extension Model: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.bool = try ValueCoder<Bool>().decode(from: container, forKey: CodingKeys.bool)
                            self.int = try ValueCoder<Int>().decode(from: container, forKey: CodingKeys.int)
                            self.double = try ValueCoder<Double>().decode(from: container, forKey: CodingKeys.double)
                            self.string = try ValueCoder<String>().decode(from: container, forKey: CodingKeys.string)
                        }
                    }

                    extension Model {
                        enum CodingKeys: String, CodingKey {
                            case bool = "bool"
                            case int = "int"
                            case double = "double"
                            case string = "string"
                        }
                    }
                    """
            )
        }
    }

    struct WithCustomCodingKeys {
        @ConformEncodable
        struct SomeEncodable {
            @CodedAt("custom_value")
            let value: String

            @CodedIn("nested", "path")
            let count: Int
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @ConformDecodable
                struct SomeDecodable {
                    @CodedAt("custom_value")
                    let value: String
                    @CodedIn("nested", "path")
                    let count: Int
                }
                """,
                expandedSource:
                    """
                    struct SomeDecodable {
                        let value: String
                        let count: Int
                    }

                    extension SomeDecodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let nested_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            let path_nested_container = try nested_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.path)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            self.count = try path_nested_container.decode(Int.self, forKey: CodingKeys.count)
                        }
                    }

                    extension SomeDecodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "custom_value"
                            case count = "count"
                            case nested = "nested"
                            case path = "path"
                        }
                    }
                    """
            )
        }
    }
}
