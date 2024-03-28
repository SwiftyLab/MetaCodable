#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class GroupedDefaultTests: XCTestCase {

    func testMisuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @GroupedDefault("some")
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
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                )
            ]
        )
    }

    func testMisuseOnStaticVariable() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @GroupedDefault("some")
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
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can't be used with single variables declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
                .init(
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
            ]
        )
    }
    
    func testNoPatternBindingMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @GroupedDefault("other")
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
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can't be used with single variables declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                )
            ]
        )
    }

    func testDuplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @GroupedDefault("some")
                @GroupedDefault("other")
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
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can't be used with single variables declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
                .init(
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
                .init(
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can't be used with single variables declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
                .init(
                    id: GroupedDefault.misuseID,
                    message:
                        "@GroupedDefault can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @GroupedDefault attribute")
                    ]
                ),
            ]
        )
    }
}
#endif
