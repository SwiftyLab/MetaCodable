import Foundation
import MetaCodable
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import PluginCore

#if canImport(SwiftSyntax600)
import SwiftSyntaxMacrosGenericTestSupport
#else
import SwiftSyntaxMacrosTestSupport
#endif

@Suite("Codable Tests")
struct CodableTests {
    
    @Suite("Codable - Available Attribute")
    struct WithoutAvailableAttribute {
        @Codable
        @available(*, deprecated, message: "Deprecated")
        struct SomeCodable {
            let value: String
            static let other: String = "other"
            public private(set) static var otherM: String {
                get { "otherM" }
                set { Issue.record("Invalid setter invocation") }
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @available(*, deprecated, message: "Deprecated")
                struct SomeCodable {
                    let value: String
                    static let other: String = "other"
                    public private(set) static var otherM: String {
                        get { "otherM" }
                        set { Issue.record("Invalid setter invocation") }
                    }
                }
                """,
                expandedSource:
                    """
                    @available(*, deprecated, message: "Deprecated")
                    struct SomeCodable {
                        let value: String
                        static let other: String = "other"
                        public private(set) static var otherM: String {
                            get { "otherM" }
                            set { Issue.record("Invalid setter invocation") }
                        }
                    }

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }

        @Test("encoding works with available attribute")
        @available(*, deprecated, message: "Deprecated")
        func availableAttributeEncoding() throws {
            let original = SomeCodable(value: "deprecated_test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "deprecated_test")
        }

        @Test("decoding from JSON works with available attribute")
        @available(*, deprecated, message: "Deprecated")
        func availableAttributeFromJSON() throws {
            let jsonStr = """
                {
                    "value": "available_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "available_value")
        }
    }

    
    @Suite("Codable - No Customization")
    struct WithoutAnyCustomization {
        @Codable
        struct SomeCodable {
            let value: String
            static let other: String = "other"
            public private(set) static var otherM: String {
                get { "otherM" }
                set { Issue.record("Invalid setter invocation") }
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    let value: String
                    static let other: String = "other"
                    public private(set) static var otherM: String {
                        get { "otherM" }
                        set { Issue.record("Invalid setter invocation") }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String
                        static let other: String = "other"
                        public private(set) static var otherM: String {
                            get { "otherM" }
                            set { Issue.record("Invalid setter invocation") }
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
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

        @Test("basic Codable encoding works")
        func basicCodableEncoding() throws {
            let original = SomeCodable(value: "basic_test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "basic_test")
        }

        @Test("basic Codable decoding from JSON works")
        func basicCodableFromJSON() throws {
            let jsonStr = """
                {
                    "value": "basic_value"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "basic_value")
        }

        @Test("static properties are ignored in encoding")
        func staticPropertiesIgnored() throws {
            let original = SomeCodable(value: "test")
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            // Static properties should not be encoded
            #expect(json["other"] == nil)
            #expect(json["otherM"] == nil)
            #expect(json["value"] as? String == "test")
        }
    }

    @Suite("Codable - No Customization")
    struct WithOptionalTypeWithoutAnyCustomization {
        @Codable
        struct SomeCodable {
            let value1: String?
            let value2: String!
            let value3: String?
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    let value1: String?
                    let value2: String!
                    let value3: Optional<String>
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: String?
                        let value2: String!
                        let value3: Optional<String>
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value1 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value1)
                            self.value2 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            self.value3 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value1, forKey: CodingKeys.value1)
                            try container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case value2 = "value2"
                            case value3 = "value3"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Codable - Partial Conformance")
    struct OnlyDecodeConformance {
        @Codable
        struct SomeCodable: Encodable {
            let value: String

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable: Encodable {
                    let value: String

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Encodable {
                        let value: String

                        func encode(to encoder: any Encoder) throws {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: ["Decodable"]
            )
        }
    }

    @Suite("Codable - Partial Conformance")
    struct OnlyEncodeConformance {
        @Codable
        struct SomeCodable: Decodable {
            let value: String

            init(from decoder: any Decoder) throws {
                self.value = "some"
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable: Decodable {
                    let value: String

                    init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Decodable {
                        let value: String

                        init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: ["Encodable"]
            )
        }
    }

    @Suite("Codable - Ignored Codable Conformance")
    struct IgnoredCodableConformance {
        @Codable
        struct SomeCodable: Swift.Codable {
            let value: String

            init(from decoder: any Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable: Codable {
                    let value: String

                    init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Codable {
                        let value: String

                        init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    @Suite("Codable - Super Class Codable Conformance")
    struct SuperClassCodableConformance {
        class SuperCodable: Swift.Codable {}
        enum AnotherDecoder {}
        enum AnotherEncoder {}

        @Codable
        class SomeCodable: SuperCodable {
            let value: String

            required init(from decoder: AnotherDecoder) throws {
                self.value = "some"
                fatalError("No super call")
            }

            func encode(to encoder: AnotherEncoder) throws {
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable: SuperCodable {
                    let value: String

                    required init(from decoder: AnotherDecoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: AnotherEncoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: SuperCodable {
                        let value: String

                        required init(from decoder: AnotherDecoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: AnotherEncoder) throws {
                        }

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            try super.init(from: decoder)
                        }

                        override func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try super.encode(to: encoder)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    @Suite("Codable - Class Ignored Codable Conformance")
    struct ClassIgnoredCodableConformance {
        @Codable
        class SomeCodable: Swift.Codable {
            let value: String

            required init(from decoder: any Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable: Codable {
                    let value: String

                    required init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: Codable {
                        let value: String

                        required init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    @Suite("Codable - Without")
    struct ClassIgnoredCodableConformanceWithoutAny {
        @Codable
        class SomeCodable: Swift.Codable {
            let value: String

            required init(from decoder: Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: Encoder) throws {
            }
        }

        @Test("expansion generates correct Codable implementation")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class SomeCodable: Swift.Codable {
                    let value: String

                    required init(from decoder: Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: Swift.Codable {
                        let value: String

                        required init(from decoder: Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }
}

#if canImport(MacroPlugin)
@testable import MacroPlugin

let allMacros: [String: (Macro & Sendable).Type] = [
    "CodedAt": MacroPlugin.CodedAt.self,
    "DecodedAt": MacroPlugin.DecodedAt.self,
    "EncodedAt": MacroPlugin.EncodedAt.self,
    "CodedIn": MacroPlugin.CodedIn.self,
    "Default": MacroPlugin.Default.self,
    "CodedBy": MacroPlugin.CodedBy.self,
    "CodedAs": MacroPlugin.CodedAs.self,
    "ContentAt": MacroPlugin.ContentAt.self,
    "IgnoreCoding": MacroPlugin.IgnoreCoding.self,
    "IgnoreDecoding": MacroPlugin.IgnoreDecoding.self,
    "IgnoreEncoding": MacroPlugin.IgnoreEncoding.self,
    "Codable": MacroPlugin.Codable.self,
    "ConformDecodable": MacroPlugin.ConformDecodable.self,
    "ConformEncodable": MacroPlugin.ConformEncodable.self,
    "MemberInit": MacroPlugin.MemberInit.self,
    "CodingKeys": MacroPlugin.CodingKeys.self,
    "IgnoreCodingInitialized": MacroPlugin.IgnoreCodingInitialized.self,
    "Inherits": MacroPlugin.Inherits.self,
    "UnTagged": MacroPlugin.UnTagged.self,
]
#else
let allMacros: [String: (Macro & Sendable).Type] = [
    "CodedAt": CodedAt.self,
    "DecodedAt": DecodedAt.self,
    "EncodedAt": EncodedAt.self,
    "CodedIn": CodedIn.self,
    "Default": Default.self,
    "CodedBy": CodedBy.self,
    "CodedAs": CodedAs.self,
    "ContentAt": ContentAt.self,
    "IgnoreCoding": IgnoreCoding.self,
    "IgnoreDecoding": IgnoreDecoding.self,
    "IgnoreEncoding": IgnoreEncoding.self,
    "Codable": Codable.self,
    "ConformDecodable": ConformDecodable.self,
    "ConformEncodable": ConformEncodable.self,
    "MemberInit": MemberInit.self,
    "CodingKeys": CodingKeys.self,
    "IgnoreCodingInitialized": IgnoreCodingInitialized.self,
    "Inherits": Inherits.self,
    "UnTagged": UnTagged.self,
]
#endif

func assertMacroExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    conformsTo conformances: [TypeSyntax] = ["Decodable", "Encodable"],
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID, filePath: StaticString = #filePath,
    file: StaticString = #file, line: UInt = #line, column: UInt = #column
) {
    #if canImport(SwiftSyntax600)
    assertMacroExpansion(
        originalSource, expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: allMacros.mapValues { value in
            MacroSpec(type: value, conformances: conformances)
        },
        testModuleName: testModuleName, testFileName: testFileName,
        indentationWidth: indentationWidth
    ) { spec in
        #if swift(>=6)
        Issue.record(
            .init(rawValue: spec.message),
            sourceLocation: .init(
                fileID: String(fileID), filePath: String(filePath),
                line: Int(line), column: Int(column)
            )
        )
        #else
        Issue.record(
            .init(rawValue: spec.message),
            sourceLocation: .init(
                fileID: fileID, filePath: filePath, line: line, column: column
            )
        )
        #endif
    }
    #else
    assertMacroExpansion(
        originalSource, expandedSource: expandedSource,
        diagnostics: diagnostics,
        macros: allMacros,
        testModuleName: testModuleName, testFileName: testFileName,
        file: file, line: line
    )
    #endif
}

extension String {
    init(_ staticString: StaticString) {
        self = staticString.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
    }
}

extension Attribute {
    static var misuseID: MessageID {
        Self.init(
            from: .init(
                attributeName: IdentifierTypeSyntax(
                    name: .identifier(Self.name)
                )
            )
        )!.misuseMessageID
    }
}

extension DiagnosticSpec {
    static func multiBinding(line: Int, column: Int) -> Self {
        .init(
            id: MessageID(
                domain: "SwiftSyntaxMacroExpansion",
                id: "peerMacroOnVariableWithMultipleBindings"
            ),
            message: "peer macro can only be applied to a single variable",
            line: line, column: column
        )
    }
}

extension Tag {
    @Tag
    static var `struct`: Self
    @Tag
    static var `class`: Self
    @Tag
    static var `enum`: Self
    @Tag
    static var actor: Self
    @Tag
    static var external: Self
    @Tag
    static var `internal`: Self
    @Tag
    static var adjacent: Self
}

#if swift(<6)
import XCTest

final class CodableXCTests: XCTestCase {
    func testNothing() {}
}
#endif
