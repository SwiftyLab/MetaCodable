import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Default Tests")
struct DefaultTests {
    @Test("misuse On Non Variable Declaration")
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default("some")
                func someFunc() {
                }
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    func someFunc() {
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: Default.misuseID,
                    message:
                        "@Default only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                )
            ]
        )
    }

    @Test("misuse On Static Variable")
    func misuseOnStaticVariable() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default("some")
                static let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    static let value: String
                }
                """,
            diagnostics: [
                .init(
                    id: Default.misuseID,
                    message:
                        "@Default can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                )
            ]
        )
    }

    @Test("duplicated Misuse")
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default("some")
                @Default("other")
                let one: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String
                }
                """,
            diagnostics: [
                .init(
                    id: Default.misuseID,
                    message:
                        "@Default can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                ),
                .init(
                    id: Default.misuseID,
                    message:
                        "@Default can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                ),
            ]
        )
    }

    @Suite("Default - Default Value Behavior")
    struct DefaultValueBehavior {
        @Codable
        struct SomeCodable {
            @Default("default_value")
            let value: String
            @Default(42)
            let number: Int
        }

        @Test("default Value Usage")
        func defaultValueUsage() throws {
            // Test with missing keys in JSON
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "default_value")
            #expect(decoded.number == 42)
        }

        @Test("override Default Values")
        func overrideDefaultValues() throws {
            // Test with provided values in JSON
            let jsonStr = """
                {
                    "value": "custom_value",
                    "number": 100
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "custom_value")
            #expect(decoded.number == 100)
        }

        @Test("encoding With Defaults")
        func encodingWithDefaults() throws {
            let original = SomeCodable(value: "test", number: 99)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "test")
            #expect(decoded.number == 99)
        }
    }
}
