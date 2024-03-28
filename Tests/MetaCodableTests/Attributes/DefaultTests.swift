#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class DefaultTests: XCTestCase {

    func testMisuseOnNonVariableDeclaration() throws {
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

    func testMisuseOnStaticVariable() throws {
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

    func testDuplicatedMisuse() throws {
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
    
    func testMissingDefaultValue() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default()
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
                        "@Default missing default value for variable 'one'",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                ),
            ]
        )
    }
    
    func testMissingDefaultValues() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default("hello")
                let one: String, two: Int
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let one: String, two: Int
                }
                """,
            diagnostics: [
                .multiBinding(line: 2, column: 5)
            ]
        )
    }
    
    func testTooManyDefaultValueParameters() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @Default("hello", 10)
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
                        "@Default expect 1 default value but found 2 !",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @Default attribute")
                    ]
                ),
            ]
        )
    }
}
#endif
