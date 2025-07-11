import MetaCodable
import Testing

@testable import PluginCore

struct VariableDeclarationTests {
    struct InitializedImmutableVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String = "some"
        }

        @Test
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
    }

    struct InitializedMutableVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String = "some"
        }

        @Test
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

    struct GetterOnlyVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String { "some" }
        }

        @Test
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

    struct ExplicitGetterOnlyVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String {
                "some"
            }
        }

        @Test
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

    struct GetterOnlyVariableWithMultiLineStatements {
        @Codable
        @MemberInit
        struct SomeCodable {
            var value: String {
                let val = "Val"
                return "some\(val)"
            }
        }

        @Test
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

        @Test
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

        @Test
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

        @Test
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

    struct OptionalSyntaxVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String?
        }

        @Test
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

    struct GenericSyntaxOptionalVariable {
        @Codable
        @MemberInit
        struct SomeCodable {
            let value: String?
        }

        @Test
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
