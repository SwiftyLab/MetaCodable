import Testing

@testable import PluginCore

struct CodedByTests {
    @Test
    func misuseOnNonVariableDeclaration() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedBy(Since1970DateCoder())
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
                    id: CodedBy.misuseID,
                    message:
                        "@CodedBy only applicable to variable declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedBy attribute")
                    ]
                )
            ]
        )
    }

    @Test
    func misuseOnStaticVariable() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedBy(Since1970DateCoder())
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
                    id: CodedBy.misuseID,
                    message:
                        "@CodedBy can't be used with static variables declarations",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedBy attribute")
                    ]
                )
            ]
        )
    }

    @Test
    func duplicatedMisuse() throws {
        assertMacroExpansion(
            """
            struct SomeCodable {
                @CodedBy(Since1970DateCoder())
                @CodedBy(Since1970DateCoder())
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
                    id: CodedBy.misuseID,
                    message:
                        "@CodedBy can only be applied once per declaration",
                    line: 2, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedBy attribute")
                    ]
                ),
                .init(
                    id: CodedBy.misuseID,
                    message:
                        "@CodedBy can only be applied once per declaration",
                    line: 3, column: 5,
                    fixIts: [
                        .init(message: "Remove @CodedBy attribute")
                    ]
                ),
            ]
        )
    }
}
