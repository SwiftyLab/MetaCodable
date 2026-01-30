import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Variable Declaration Tests")
struct VariableDeclarationTests {
    @Suite("Variable Declaration - Initialized Immutable Variable")
    struct InitializedImmutableVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String = "some"
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #101)", .tags(.codable, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    let value: String = "some"
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String = "some"

                        init() {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
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

        @Test("Encodes and decodes successfully (VariableDeclarationTests #38)", .tags(.decoding, .encoding))
        func decodingAndEncoding() throws {
            let original = SomeCodable()
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: encoded)
            #expect(decoded.value == "some")
        }

        @Test("Decodes from JSON successfully (VariableDeclarationTests #101)", .tags(.decoding))
        func decodingFromEmptyJSON() throws {
            let jsonStr = "{}"
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                SomeCodable.self, from: jsonData)
            #expect(decoded.value == "some")
        }

        @Test("Encodes to JSON successfully (VariableDeclarationTests #24)", .tags(.encoding, .optionals))
        func encodingToJSON() throws {
            let original = SomeCodable()
            let encoded = try JSONEncoder().encode(original)
            let json =
                try JSONSerialization.jsonObject(with: encoded)
                as! [String: Any]
            #expect(json["value"] as? String == "some")
        }
    }

    @Suite("Variable Declaration - Initialized Mutable Variable")
    struct InitializedMutableVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String = "some"
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #102)", .tags(.codable, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value: String = "some"
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String = "some"

                        init() {
                        }

                        init(value: String) {
                            self.value = value
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
    }

    @Suite("Variable Declaration - Getter Only Variable")
    struct GetterOnlyVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String { "some" }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #103)", .tags(.codable, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value: String { "some" }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String { "some" }

                        init() {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Explicit Getter Only Variable")
    struct ExplicitGetterOnlyVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String {
                "some"
            }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #104)", .tags(.codable, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value: String {
                        get {
                            "some"
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            get {
                                "some"
                            }
                        }

                        init() {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Getter Only Variable With Multi Line Statements")
    struct GetterOnlyVariableWithMultiLineStatements {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #105)", .tags(.codable, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value: String {
                        let val = "Val"
                        return "some\\(val)"
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            let val = "Val"
                            return "some\\(val)"
                        }

                        init() {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Variable With Property Observers")
    struct VariableWithPropertyObservers {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value1: String {
                didSet {
                }
            }

            var value2: String {
                willSet {
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #106)", .tags(.codable, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value1: String {
                        didSet {
                        }
                    }

                    var value2: String {
                        willSet {
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value1: String {
                            didSet {
                            }
                        }

                        var value2: String {
                            willSet {
                            }
                        }

                        init(value1: String, value2: String) {
                            self.value1 = value1
                            self.value2 = value2
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value1 = try container.decode(String.self, forKey: CodingKeys.value1)
                            self.value2 = try container.decode(String.self, forKey: CodingKeys.value2)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value1, forKey: CodingKeys.value1)
                            try container.encode(self.value2, forKey: CodingKeys.value2)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case value2 = "value2"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Initialized Variable With Property Observers")
    struct InitializedVariableWithPropertyObservers {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value1: String = "some" {
                didSet {
                }
            }

            var value2: String = "some" {
                willSet {
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #107)", .tags(.codable, .decoding, .encoding, .enums, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value1: String = "some" {
                        didSet {
                        }
                    }

                    var value2: String = "some" {
                        willSet {
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value1: String = "some" {
                            didSet {
                            }
                        }

                        var value2: String = "some" {
                            willSet {
                            }
                        }

                        init() {
                        }

                        init(value1: String) {
                            self.value1 = value1
                        }

                        init(value2: String) {
                            self.value2 = value2
                        }

                        init(value1: String, value2: String) {
                            self.value1 = value1
                            self.value2 = value2
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value1 = try container.decode(String.self, forKey: CodingKeys.value1)
                            self.value2 = try container.decode(String.self, forKey: CodingKeys.value2)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value1, forKey: CodingKeys.value1)
                            try container.encode(self.value2, forKey: CodingKeys.value2)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case value2 = "value2"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Computed Property")
    struct ComputedProperty {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String {
                get {
                    "some"
                }
                set {
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #108)", .tags(.codable, .macroExpansion, .memberInit, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    var value: String {
                        get {
                            "some"
                        }
                        set {
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        var value: String {
                            get {
                                "some"
                            }
                            set {
                            }
                        }

                        init() {
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """
            )
        }
    }

    @Suite("Variable Declaration - Optional Syntax Variable")
    struct OptionalSyntaxVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct (VariableDeclarationTests #109)", .tags(.codable, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    let value: String?
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String?

                        init(value: String? = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )

            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    let value: String!
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String!

                        init(value: String! = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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
    }

    @Suite("Variable Declaration - Generic Syntax Optional Variable")
    struct GenericSyntaxOptionalVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String?
        }

        @Test("Generates macro expansion with @Codable for struct with optional properties (VariableDeclarationTests #1)", .tags(.codable, .enums, .macroExpansion, .memberInit, .optionals, .structs))
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @MemberInit
                struct SomeCodable {
                    let value: Optional<String>
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: Optional<String>

                        init(value: Optional<String> = nil) {
                            self.value = value
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value, forKey: CodingKeys.value)
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
    }
}
