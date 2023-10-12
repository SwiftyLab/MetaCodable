import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import CodableMacroPlugin

final class CodableTests: XCTestCase {
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
            """,
            diagnostics: [
                .init(
                    id: Codable.misuseID,
                    message: "@Codable only applicable to struct declarations",
                    line: 1, column: 1,
                    fixIts: [
                        .init(message: "Remove @Codable attribute"),
                    ]
                ),
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
            }

            extension SomeCodable: Decodable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try container.decode(String.self, forKey: CodingKeys.value)
                }
            }

            extension SomeCodable: Encodable {
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.value, forKey: CodingKeys.value)
                }
            }

            extension SomeCodable {
                enum CodingKeys: String, CodingKey {
                    case value = "value"
                }
            }
            """
        )
    }

    func testOnlyDecodeConformance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable: Encodable {
                let value: String

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            expandedSource:
            """
            struct SomeCodable: Encodable {
                let value: String

                func encode(to encoder: Encoder) throws {
                }
            }

            extension SomeCodable: Decodable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try container.decode(String.self, forKey: CodingKeys.value)
                }
            }

            extension SomeCodable {
                enum CodingKeys: String, CodingKey {
                    case value = "value"
                }
            }
            """
        )
    }

    func testOnlyEncodeConformance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable: Decodable {
                let value: String

                init(from decoder: Decoder) throws {
                    self.value = "some"
                }
            }
            """,
            expandedSource:
            """
            struct SomeCodable: Decodable {
                let value: String

                init(from decoder: Decoder) throws {
                    self.value = "some"
                }
            }

            extension SomeCodable: Encodable {
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.value, forKey: CodingKeys.value)
                }
            }

            extension SomeCodable {
                enum CodingKeys: String, CodingKey {
                    case value = "value"
                }
            }
            """
        )
    }

    func testIgnoredCodableConformance() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable: Codable {
                let value: String

                init(from decoder: Decoder) throws {
                    self.value = "some"
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            expandedSource:
            """
            struct SomeCodable: Codable {
                let value: String

                init(from decoder: Decoder) throws {
                    self.value = "some"
                }

                func encode(to encoder: Encoder) throws {
                }
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
            "CodedAt": CodedAt.self,
            "CodedIn": CodedIn.self,
            "Default": Default.self,
            "CodedBy": CodedBy.self,
            "IgnoreCoding": IgnoreCoding.self,
            "IgnoreDecoding": IgnoreDecoding.self,
            "IgnoreEncoding": IgnoreEncoding.self,
            "Codable": Codable.self,
            "MemberInit": MemberInit.self,
            "CodingKeys": CodingKeys.self,
            "IgnoreCodingInitialized": IgnoreCodingInitialized.self,
        ],
        testModuleName: testModuleName, testFileName: testFileName,
        indentationWidth: indentationWidth,
        file: file, line: line
    )
}

extension Attribute {
    static var misuseID: MessageID {
        Self(from: .init(stringLiteral: name))!.misuseMessageID
    }
}

extension DiagnosticSpec {
    static func multiBinding(line: Int, column: Int) -> Self {
        .init(
            id: MessageID(
                domain: "SwiftSyntaxMacroExpansion",
                id: "accessorMacroOnVariableWithMultipleBindings"
            ),
            message:
            "swift-syntax applies macros syntactically and"
                + " there is no way to represent a variable declaration"
                + " with multiple bindings that have accessors syntactically."
                + " While the compiler allows this expansion,"
                + " swift-syntax cannot represent it and thus disallows it.",
            line: line, column: column
        )
    }
}
