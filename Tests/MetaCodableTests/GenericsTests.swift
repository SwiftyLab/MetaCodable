import Foundation
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Generics Tests")
struct GenericsTests {
    @Suite("Generics - Single Generic Type Expansion")
    struct SingleGenericTypeExpansion {
        @Codable
        struct GenericCodable<T> {
            let value: T
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T> {
                    let value: T
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T> {
                        let value: T
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(T.self, forKey: CodingKeys.value)
                        }
                    }

                    extension GenericCodable: Encodable where T: Encodable {
                        func encode(to encoder: any Encoder) throws where T: Encodable {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }

        @Test("decoding And Encoding")
        func decodingAndEncoding() throws {
            let original = GenericCodable(value: "test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                GenericCodable<String>.self, from: encoded)
            #expect(decoded.value == "test")
        }

        @Test("decoding And Encoding With Int")
        func decodingAndEncodingWithInt() throws {
            let original = GenericCodable(value: 42)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                GenericCodable<Int>.self, from: encoded)
            #expect(decoded.value == 42)
        }

        @Test("decoding From J S O N")
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "value": "hello"
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                GenericCodable<String>.self, from: jsonData)
            #expect(decoded.value == "hello")
        }
    }

    @Suite("Generics - Multiple Generic Type Expansion")
    struct MultipleGenericTypeExpansion {
        @Codable
        struct GenericCodable<T, U, V> {
            let value1: T
            let value2: U
            let value3: V
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T, U, V> {
                    let value1: T
                    let value2: U
                    let value3: V
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T, U, V> {
                        let value1: T
                        let value2: U
                        let value3: V
                    }

                    extension GenericCodable: Decodable where T: Decodable, U: Decodable, V: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable, U: Decodable, V: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value1 = try container.decode(T.self, forKey: CodingKeys.value1)
                            self.value2 = try container.decode(U.self, forKey: CodingKeys.value2)
                            self.value3 = try container.decode(V.self, forKey: CodingKeys.value3)
                        }
                    }

                    extension GenericCodable: Encodable where T: Encodable, U: Encodable, V: Encodable {
                        func encode(to encoder: any Encoder) throws where T: Encodable, U: Encodable, V: Encodable {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value1, forKey: CodingKeys.value1)
                            try container.encode(self.value2, forKey: CodingKeys.value2)
                            try container.encode(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case value2 = "value2"
                            case value3 = "value3"
                        }
                    }
                    """
            )
        }

        @Test("decoding And Encoding")
        func decodingAndEncoding() throws {
            let original = GenericCodable(
                value1: "test", value2: 42, value3: true)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                GenericCodable<String, Int, Bool>.self, from: encoded)
            #expect(decoded.value1 == "test")
            #expect(decoded.value2 == 42)
            #expect(decoded.value3 == true)
        }

        @Test("decoding From J S O N")
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "value1": "hello",
                    "value2": 100,
                    "value3": false
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                GenericCodable<String, Int, Bool>.self, from: jsonData)
            #expect(decoded.value1 == "hello")
            #expect(decoded.value2 == 100)
            #expect(decoded.value3 == false)
        }
    }

    @Suite("Generics - Enum Multiple Generic Type Expansion")
    struct EnumMultipleGenericTypeExpansion {
        @Codable
        enum GenericCodable<T, U, V> {
            case one(T)
            case two(U)
            case three(V)
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum GenericCodable<T, U, V> {
                    case one(T)
                    case two(U)
                    case three(V)
                }
                """,
                expandedSource:
                    """
                    enum GenericCodable<T, U, V> {
                        case one(T)
                        case two(U)
                        case three(V)
                    }

                    extension GenericCodable: Decodable where T: Decodable, U: Decodable, V: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable, U: Decodable, V: Decodable {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.one:
                                let _0: T
                                _0 = try T(from: contentDecoder)
                                self = .one(_0)
                            case DecodingKeys.two:
                                let _0: U
                                _0 = try U(from: contentDecoder)
                                self = .two(_0)
                            case DecodingKeys.three:
                                let _0: V
                                _0 = try V(from: contentDecoder)
                                self = .three(_0)
                            }
                        }
                    }

                    extension GenericCodable: Encodable where T: Encodable, U: Encodable, V: Encodable {
                        func encode(to encoder: any Encoder) throws where T: Encodable, U: Encodable, V: Encodable {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .one(let _0):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.one)
                                try _0.encode(to: contentEncoder)
                            case .two(let _0):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.two)
                                try _0.encode(to: contentEncoder)
                            case .three(let _0):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.three)
                                try _0.encode(to: contentEncoder)
                            }
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                            case three = "three"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                            case three = "three"
                        }
                    }
                    """
            )
        }

        @Test("decoding And Encoding Case One")
        func decodingAndEncodingCaseOne() throws {
            let original: GenericCodable<String, Int, Bool> = .one("test")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                GenericCodable<String, Int, Bool>.self, from: encoded)
            if case .one(let value) = decoded {
                #expect(value == "test")
            } else {
                Issue.record("Expected .one case")
            }
        }

        @Test("decoding And Encoding Case Two")
        func decodingAndEncodingCaseTwo() throws {
            let original: GenericCodable<String, Int, Bool> = .two(42)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(
                GenericCodable<String, Int, Bool>.self, from: encoded)
            if case .two(let value) = decoded {
                #expect(value == 42)
            } else {
                Issue.record("Expected .two case")
            }
        }

        @Test("decoding From J S O N")
        func decodingFromJSON() throws {
            let jsonStr = """
                {
                    "three": true
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(
                GenericCodable<String, Int, Bool>.self, from: jsonData)
            if case .three(let value) = decoded {
                #expect(value == true)
            } else {
                Issue.record("Expected .three case")
            }
        }
    }

    @Suite("Generics - Mixed Generic Type Expansion")
    struct MixedGenericTypeExpansion {
        @Codable
        struct GenericCodable<T> {
            let value: T
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T> {
                    let value: T
                    let str: String
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T> {
                        let value: T
                        let str: String
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(T.self, forKey: CodingKeys.value)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable: Encodable where T: Encodable {
                        func encode(to encoder: any Encoder) throws where T: Encodable {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case str = "str"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Generics - Class Mixed Generic Type Expansion")
    struct ClassMixedGenericTypeExpansion {
        @Codable
        class GenericCodable<T> {
            let value: T
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class GenericCodable<T> {
                    let value: T
                    let str: String
                }
                """,
                expandedSource:
                    """
                    class GenericCodable<T> {
                        let value: T
                        let str: String

                        required init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(T.self, forKey: CodingKeys.value)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }

                        func encode(to encoder: any Encoder) throws where T: Encodable {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case str = "str"
                        }
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                    }

                    extension GenericCodable: Encodable where T: Encodable {
                    }
                    """
            )
        }
    }

    @Suite("Generics - Enum Mixed Generic Type Expansion")
    struct EnumMixedGenericTypeExpansion {
        @Codable
        enum GenericCodable<T> {
            @IgnoreEncoding
            case one(T)
            case two(String)
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum GenericCodable<T> {
                    @IgnoreEncoding
                    case one(T)
                    case two(String)
                }
                """,
                expandedSource:
                    """
                    enum GenericCodable<T> {
                        case one(T)
                        case two(String)
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.one:
                                let _0: T
                                _0 = try T(from: contentDecoder)
                                self = .one(_0)
                            case DecodingKeys.two:
                                let _0: String
                                _0 = try String(from: contentDecoder)
                                self = .two(_0)
                            }
                        }
                    }

                    extension GenericCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .two(let _0):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.two)
                                try _0.encode(to: contentEncoder)
                            default:
                                break
                            }
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case two = "two"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Generics - Ignored Generic Type Expansion")
    struct IgnoredGenericTypeExpansion {
        @Codable
        struct GenericCodable<T> {
            var value: T { fatalError("Not Implemented") }
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T> {
                    var value: T { fatalError("Not Implemented") }
                    let str: String
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T> {
                        var value: T { fatalError("Not Implemented") }
                        let str: String
                    }

                    extension GenericCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case str = "str"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Generics - Helper Coded Generic Type Expansion")
    struct HelperCodedGenericTypeExpansion {
        @Codable
        struct GenericCodable<T> {
            @CodedBy(TestCoder<T>())
            let value: T
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T> {
                    @CodedBy(TestCoder<T>())
                    let value: T
                    let str: String
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T> {
                        let value: T
                        let str: String
                    }

                    extension GenericCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try TestCoder<T>().decode(from: container, forKey: CodingKeys.value)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try TestCoder<T>().encode(self.value, to: &container, atKey: CodingKeys.value)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case str = "str"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Generics - Ignored Encoding Generic Type Expansion")
    struct IgnoredEncodingGenericTypeExpansion {
        @Codable
        struct GenericCodable<T> {
            @IgnoreEncoding
            let value: T
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                struct GenericCodable<T> {
                    @IgnoreEncoding
                    let value: T
                    let str: String
                }
                """,
                expandedSource:
                    """
                    struct GenericCodable<T> {
                        let value: T
                        let str: String
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(T.self, forKey: CodingKeys.value)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case str = "str"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Generics - Class Ignored Encoding Generic Type Expansion")
    struct ClassIgnoredEncodingGenericTypeExpansion {
        @Codable
        class GenericCodable<T> {
            @IgnoreEncoding
            let value: T
            let str: String
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                class GenericCodable<T> {
                    @IgnoreEncoding
                    let value: T
                    let str: String
                }
                """,
                expandedSource:
                    """
                    class GenericCodable<T> {
                        let value: T
                        let str: String

                        required init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(T.self, forKey: CodingKeys.value)
                            self.str = try container.decode(String.self, forKey: CodingKeys.str)
                        }

                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.str, forKey: CodingKeys.str)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                            case str = "str"
                        }
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                    }

                    extension GenericCodable: Encodable {
                    }
                    """
            )
        }
    }

    @Suite("Generics - Enum Ignored Encoding Generic Type Expansion")
    struct EnumIgnoredEncodingGenericTypeExpansion {
        @Codable
        enum GenericCodable<T> {
            @IgnoreEncoding
            case one(T)
            case two(String)
        }

        @Test("expansion")
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum GenericCodable<T> {
                    @IgnoreEncoding
                    case one(T)
                    case two(String)
                }
                """,
                expandedSource:
                    """
                    enum GenericCodable<T> {
                        case one(T)
                        case two(String)
                    }

                    extension GenericCodable: Decodable where T: Decodable {
                        init(from decoder: any Decoder) throws where T: Decodable {
                            let container = try decoder.container(keyedBy: DecodingKeys.self)
                            guard container.allKeys.count == 1 else {
                                let context = DecodingError.Context(
                                    codingPath: container.codingPath,
                                    debugDescription: "Invalid number of keys found, expected one."
                                )
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.one:
                                let _0: T
                                _0 = try T(from: contentDecoder)
                                self = .one(_0)
                            case DecodingKeys.two:
                                let _0: String
                                _0 = try String(from: contentDecoder)
                                self = .two(_0)
                            }
                        }
                    }

                    extension GenericCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            switch self {
                            case .two(let _0):
                                let contentEncoder = container.superEncoder(forKey: CodingKeys.two)
                                try _0.encode(to: contentEncoder)
                            default:
                                break
                            }
                        }
                    }

                    extension GenericCodable {
                        enum CodingKeys: String, CodingKey {
                            case two = "two"
                        }
                        enum DecodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                        }
                    }
                    """
            )
        }
    }
}

private struct TestCoder<Coded>: HelperCoder {
    func decode(from decoder: any Decoder) throws -> Coded {
        throw CancellationError()
    }
}
