import XCTest
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroPlugin

final class CodableMacroTests: XCTestCase {

    func testMisuseOnNonStructDeclaration() throws {
        assertMacroExpansion(
            """
            @Codable
            enum SomeCodable: String {
                case value
            }
            """,
            expandedSource:
                """
                enum SomeCodable: String {
                    case value
                }
                extension SomeCodable: Codable {
                }
                """,
            diagnostics: [
                .init(
                    id: Codable(from: .init("Codable"))!.misuseMessageID,
                    message: "@Codable only works for struct declarations",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @Codable attribute")
                    ]
                )
            ]
        )
    }

    func testWithoutAnyCustomization() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String
                    init(value: String) {
                        self.value = value
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}

func assertMacroExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    file: StaticString = #file,
    line: UInt = #line
) {
    assertMacroExpansion(
        originalSource, expandedSource: expandedSource,
        diagnostics: diagnostics,
        macros: [
            "Codable": CodableMacro.self,
            "CodedAt": CodedPropertyMacro.self,
            "CodedIn": CodedPropertyMacro.self,
        ],
        testModuleName: testModuleName, testFileName: testFileName,
        indentationWidth: indentationWidth,
        file: file, line: line
    )
}
