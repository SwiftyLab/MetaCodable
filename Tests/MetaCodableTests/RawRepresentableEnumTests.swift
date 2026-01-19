import Foundation
import HelperCoders
import MetaCodable
import Testing
import XCTest

@testable import PluginCore

struct RawRepresentableEnumTests {
    struct StringRepresentation {
        @Codable
        enum Status: String, CaseIterable {
            case active = "active"
            case inactive = "inactive"
            case pending = "pending"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum Status: String {
                    case active = "active"
                    case inactive = "inactive"
                    case pending = "pending"
                }
                """,
                expandedSource:
                    """
                    enum Status: String {
                        case active = "active"
                        case inactive = "inactive"
                        case pending = "pending"
                    }

                    extension Status: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeDecoder: any Decoder
                            typeDecoder = decoder
                            let rawValue: RawValue?
                            do {
                                rawValue = try RawValue(from: typeDecoder)
                            } catch {
                                rawValue = nil
                            }
                            if let rawValue = rawValue, let selfValue = Self(rawValue: rawValue) {
                                self = selfValue
                                return
                            }
                            let typeString: String?
                            do {
                                typeString = try String??(from: typeDecoder) ?? nil
                            } catch {
                                typeString = nil
                            }
                            if let typeString = typeString {
                                switch typeString {
                                case "active":
                                    self = .active
                                    return
                                case "inactive":
                                    self = .inactive
                                    return
                                case "pending":
                                    self = .pending
                                    return
                                default:
                                    break
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Status: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let typeEncoder = encoder
                            try rawValue.encode(to: typeEncoder)
                        }
                    }
                    """
            )
        }

        @Test(arguments: Status.allCases)
        func decoding(status: Status) throws {
            struct StatusRootType: Swift.Codable {
                let type: StatusType

                struct StatusType: Swift.Codable {
                    let type: Status
                }
            }

            let jsonString = """
                {"type": {"type": "\(status.rawValue)"}}
                """
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(
                StatusRootType.self, from: jsonData)

            #expect(decoded.type.type == status)
        }

        @Test(arguments: Status.allCases)
        func allCasesRoundtrip(status: Status) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let encoded = try encoder.encode(status)
            let decoded = try decoder.decode(Status.self, from: encoded)
            #expect(decoded == status)
        }

        @Test
        func directDecoding() throws {
            let jsonString = "\"active\""
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(Status.self, from: jsonData)

            #expect(decoded == .active)
        }
    }

    struct IntRepresentation {
        @Codable
        enum Priority: Int, CaseIterable {
            case low = 1
            case medium = 2
            case high = 3
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                enum Priority: Int {
                    case low = 1
                    case medium = 2
                    case high = 3
                }
                """,
                expandedSource:
                    """
                    enum Priority: Int {
                        case low = 1
                        case medium = 2
                        case high = 3
                    }

                    extension Priority: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeDecoder: any Decoder
                            typeDecoder = decoder
                            let rawValue: RawValue?
                            do {
                                rawValue = try RawValue(from: typeDecoder)
                            } catch {
                                rawValue = nil
                            }
                            if let rawValue = rawValue, let selfValue = Self(rawValue: rawValue) {
                                self = selfValue
                                return
                            }
                            let typeString: String?
                            do {
                                typeString = try String??(from: typeDecoder) ?? nil
                            } catch {
                                typeString = nil
                            }
                            if let typeString = typeString {
                                switch typeString {
                                case "low":
                                    self = .low
                                    return
                                case "medium":
                                    self = .medium
                                    return
                                case "high":
                                    self = .high
                                    return
                                default:
                                    break
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Priority: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let typeEncoder = encoder
                            try rawValue.encode(to: typeEncoder)
                        }
                    }
                    """
            )
        }

        @Test(arguments: Priority.allCases)
        func roundtrip(priority: Priority) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(priority)
            let decoded = try decoder.decode(Priority.self, from: encoded)

            #expect(decoded == priority)
        }

        @Test(arguments: Priority.allCases)
        func encoding(priority: Priority) throws {
            let encoder = JSONEncoder()

            let encoded = try encoder.encode(priority)
            let jsonString = String(data: encoded, encoding: .utf8)!

            #expect(jsonString == "\(priority.rawValue)")
        }

        @Test(arguments: Priority.allCases)
        func decoding(priority: Priority) throws {
            struct PriorityRootType: Swift.Codable {
                let type: PriorityType

                struct PriorityType: Swift.Codable {
                    let type: Priority
                }
            }

            let jsonString = """
                {"type": {"type": \(priority.rawValue)}}
                """
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(
                PriorityRootType.self, from: jsonData)

            #expect(decoded.type.type == priority)
        }
    }

    struct WithCodedAt {
        @Codable
        @CodedAt("level")
        enum Level: String, CaseIterable {
            case beginner = "beginner"
            case intermediate = "intermediate"
            case advanced = "advanced"
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Codable
                @CodedAt("status")
                enum Status: String {
                    case active = "active"
                    case inactive = "inactive"
                }
                """,
                expandedSource:
                    """
                    enum Status: String {
                        case active = "active"
                        case inactive = "inactive"
                    }

                    extension Status: Decodable {
                        init(from decoder: any Decoder) throws {
                            var typeContainer: KeyedDecodingContainer<CodingKeys>?
                            let container = try? decoder.container(keyedBy: CodingKeys.self)
                            if let container = container {
                                typeContainer = container
                            } else {
                                typeContainer = nil
                            }
                            if let typeContainer = typeContainer {
                                let rawValue: RawValue?
                                do {
                                    rawValue = try typeContainer.decode(RawValue.self, forKey: CodingKeys.type)
                                } catch {
                                    rawValue = nil
                                }
                                if let rawValue = rawValue, let selfValue = Self(rawValue: rawValue) {
                                    self = selfValue
                                    return
                                }
                                let typeString: String?
                                do {
                                    typeString = try typeContainer.decodeIfPresent(String.self, forKey: CodingKeys.type) ?? nil
                                } catch {
                                    typeString = nil
                                }
                                if let typeString = typeString {
                                    switch typeString {
                                    case "active":
                                        self = .active
                                        return
                                    case "inactive":
                                        self = .inactive
                                        return
                                    default:
                                        break
                                    }
                                }
                            }
                            let context = DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Couldn't match any cases."
                            )
                            throw DecodingError.typeMismatch(Self.self, context)
                        }
                    }

                    extension Status: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            let container = encoder.container(keyedBy: CodingKeys.self)
                            var typeContainer = container
                            try typeContainer.encode(rawValue, forKey: CodingKeys.type)
                        }
                    }

                    extension Status {
                        enum CodingKeys: String, CodingKey {
                            case type = "status"
                        }
                    }
                    """
            )
        }

        @Test(arguments: Level.allCases)
        func roundtrip(level: Level) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(level)
            let decoded = try decoder.decode(Level.self, from: encoded)

            #expect(decoded == level)
        }

        @Test(arguments: Level.allCases)
        func encoding(level: Level) throws {
            let encoder = JSONEncoder()

            let encoded = try encoder.encode(level)
            let jsonString = String(data: encoded, encoding: .utf8)!

            #expect(jsonString == "{\"level\":\"\(level.rawValue)\"}")
        }

        @Test(arguments: Level.allCases)
        func decoding(level: Level) throws {
            let jsonString = """
                {"level": "\(level.rawValue)"}
                """
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(Level.self, from: jsonData)

            #expect(decoded == level)
        }
    }

    struct WithCodedAs {
        @Codable
        enum Command: String {
            @CodedAs("load", 12, true, 3.14, 15..<20, (-0.8)...)
            case load
            @CodedAs("store", 30, false, 7.15, 35...40, ..<(-1.5))
            case store
        }

        @Codable
        enum HTTPMethod: String, CaseIterable {
            @CodedAs("GET")
            case get = "get"
            @CodedAs("POST")
            case post = "post"
            @CodedAs("PUT")
            case put = "put"
            @CodedAs("DELETE")
            case delete = "delete"
        }

        @Codable
        enum ResponseCode: Int, CaseIterable {
            @CodedAs(200, 201, 202)
            case success = 200
            @CodedAs(400, 401, 403, 404)
            case clientError = 400
            @CodedAs(500, 501, 502, 503)
            case serverError = 500
        }

        @Codable
        enum LogLevel: String, CaseIterable {
            @CodedAs("DEBUG", "TRACE")
            case debug = "debug"
            @CodedAs("INFO", "INFORMATION")
            case info = "info"
            @CodedAs("WARN", "WARNING")
            case warning = "warning"
            @CodedAs("ERROR", "FATAL")
            case error = "error"
        }

        // MARK: - Basic CodedAs Tests

        @Test(arguments: HTTPMethod.allCases)
        func httpMethodRoundtrip(method: HTTPMethod) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(method)
            let decoded = try decoder.decode(HTTPMethod.self, from: encoded)

            #expect(decoded == method)
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeRoundtrip(code: ResponseCode) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(code)
            let decoded = try decoder.decode(ResponseCode.self, from: encoded)

            #expect(decoded == code)
        }
        @Test(arguments: LogLevel.allCases)
        func logLevelRoundtrip(level: LogLevel) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(level)
            let decoded = try decoder.decode(LogLevel.self, from: encoded)

            #expect(decoded == level)
        }

        @Test(arguments: HTTPMethod.allCases)
        func httpMethodEncoding(method: HTTPMethod) throws {
            let encoder = JSONEncoder()

            let encoded = try encoder.encode(method)
            let jsonString = String(data: encoded, encoding: .utf8)!

            // Should encode using raw value, not CodedAs value
            #expect(jsonString == "\"\(method.rawValue)\"")
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeEncoding(code: ResponseCode) throws {
            let encoder = JSONEncoder()

            let encoded = try encoder.encode(code)
            let jsonString = String(data: encoded, encoding: .utf8)!

            // Should encode using raw value
            #expect(jsonString == "\(code.rawValue)")
        }

        // MARK: - CodedAs Alternative Values Decoding

        @Test(
            arguments: [
                ("\"GET\"", .get),
                ("\"POST\"", .post),
                ("\"PUT\"", .put),
                ("\"DELETE\"", .delete),
            ] as [(String, HTTPMethod)])
        func httpMethodCodedAsDecoding(value: String, method: HTTPMethod) throws
        {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(HTTPMethod.self, from: jsonData)
            #expect(decoded == method)
        }

        @Test(
            arguments: [
                ("200", .success),
                ("201", .success),
                ("202", .success),
                ("400", .clientError),
                ("401", .clientError),
                ("403", .clientError),
                ("404", .clientError),
                ("500", .serverError),
                ("501", .serverError),
                ("502", .serverError),
                ("503", .serverError),
            ] as [(String, ResponseCode)])
        func responseCodeMultipleValuesDecoding(
            value: String, code: ResponseCode
        ) throws {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(ResponseCode.self, from: jsonData)
            #expect(decoded == code)
        }

        @Test(
            arguments: [
                ("\"DEBUG\"", .debug),
                ("\"TRACE\"", .debug),
                ("\"INFO\"", .info),
                ("\"INFORMATION\"", .info),
                ("\"WARN\"", .warning),
                ("\"WARNING\"", .warning),
                ("\"ERROR\"", .error),
                ("\"FATAL\"", .error),
            ] as [(String, LogLevel)])
        func logLevelMultipleStringValuesDecoding(
            value: String, level: LogLevel
        ) throws {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(LogLevel.self, from: jsonData)
            #expect(decoded == level)
        }

        // MARK: - Raw Value Fallback Tests

        @Test(
            arguments: [
                ("\"get\"", .get),  // Raw value instead of CodedAs "GET"
                ("\"post\"", .post),  // Raw value instead of CodedAs "POST"
                ("\"put\"", .put),  // Raw value instead of CodedAs "PUT"
                ("\"delete\"", .delete),  // Raw value instead of CodedAs "DELETE"
            ] as [(String, HTTPMethod)])
        func httpMethodRawValueFallback(
            value: String, method: HTTPMethod
        ) throws {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(HTTPMethod.self, from: jsonData)
            #expect(decoded == method)
        }

        @Test(
            arguments: [
                ("200", .success),  // Raw value instead of CodedAs values
                ("400", .clientError),  // Raw value instead of CodedAs values
                ("500", .serverError),  // Raw value instead of CodedAs values
            ] as [(String, ResponseCode)])
        func responseCodeRawValueFallback(
            value: String, code: ResponseCode
        ) throws {
            let jsonData = value.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(ResponseCode.self, from: jsonData)
            #expect(decoded == code)
        }

        @Test(
            arguments: [
                ("\"debug\"", .debug),  // Raw value instead of CodedAs values
                ("\"info\"", .info),  // Raw value instead of CodedAs values
                ("\"warning\"", .warning),  // Raw value instead of CodedAs values
                ("\"error\"", .error),  // Raw value instead of CodedAs values
            ] as [(String, LogLevel)])
        func logLevelRawValueFallback(value: String, level: LogLevel) throws {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(LogLevel.self, from: jsonData)
            #expect(decoded == level)
        }

        // MARK: - Complex CodedAs Values Tests

        @Test(
            arguments: [
                ("\"load\"", .load),  // String value
                ("12", .load),  // Int value
                ("true", .load),  // Bool value
                ("3.14", .load),  // Double value
                ("\"store\"", .store),  // String value
                ("30", .store),  // Int value
                ("false", .store),  // Bool value
                ("7.15", .load),  // Double value - matches (-0.8)... range for .load
                ("15", .load),  // In range 15..<20
                ("16", .load),  // In range 15..<20
                ("19", .load),  // In range 15..<20
                ("35", .store),  // In range 35...40
                ("38", .store),  // In range 35...40
                ("40", .store),  // In range 35...40
                ("-0.8", .load),  // Exactly -0.8 from (-0.8)...
                ("0.0", .load),  // Greater than -0.8
                ("10.5", .load),  // Greater than -0.8
                ("-2.0", .store),  // Less than -1.5 from ..<(-1.5)
                ("-3.7", .store),  // Less than -1.5
            ] as [(String, Command)])
        func commandComplexCodedAsDecoding(
            value: String, command: Command
        ) throws {
            let decoder = JSONDecoder()
            let jsonData = value.data(using: .utf8)!
            let decoded = try decoder.decode(Command.self, from: jsonData)
            #expect(decoded == command)
        }

        // MARK: - Error Cases

        @Test
        func invalidCodedAsValueDecoding() throws {
            let jsonString = "\"INVALID\""
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            #expect(throws: DecodingError.self) {
                try decoder.decode(HTTPMethod.self, from: jsonData)
            }
        }

        @Test
        func invalidResponseCodeDecoding() throws {
            let jsonString = "999"  // Not in any CodedAs range
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            #expect(throws: DecodingError.self) {
                try decoder.decode(ResponseCode.self, from: jsonData)
            }
        }

        // MARK: - Array and Collection Tests

        @Test
        func httpMethodArrayDecoding() throws {
            // Test that we can decode arrays with mixed CodedAs and raw values
            let jsonString = """
                ["GET", "post", "PUT", "delete"]
                """
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode([HTTPMethod].self, from: jsonData)
            let expected: [HTTPMethod] = [
                HTTPMethod.get, HTTPMethod.post, HTTPMethod.put,
                HTTPMethod.delete,
            ]

            #expect(decoded == expected)
        }

        @Test
        func responseCodeArrayDecoding() throws {
            // Test decoding array of response codes with CodedAs values
            let jsonString = """
                [200, 201, 400, 404, 500, 503]
                """
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(
                [ResponseCode].self, from: jsonData)
            let expected: [ResponseCode] = [
                ResponseCode.success,  // 200
                ResponseCode.success,  // 201
                ResponseCode.clientError,  // 400
                ResponseCode.clientError,  // 404
                ResponseCode.serverError,  // 500
                ResponseCode.serverError,  // 503
            ]

            #expect(decoded == expected)
        }
    }

    struct WithCodedBy {
        @Codable
        @CodedBy(ValueCoder<Int>())
        enum ResponseCode: Int, CaseIterable {
            case success = 200
            case clientError = 400
            case serverError = 500
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeRoundtrip(code: ResponseCode) throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(code)
            let decoded = try decoder.decode(ResponseCode.self, from: encoded)

            #expect(decoded == code)
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeEncoding(code: ResponseCode) throws {
            let encoder = JSONEncoder()

            let encoded = try encoder.encode(code)
            let jsonString = String(data: encoded, encoding: .utf8)!

            // Should encode using raw value
            #expect(jsonString == "\(code.rawValue)")
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeDecoding(code: ResponseCode) throws {
            let jsonString = "\(code.rawValue)"
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(ResponseCode.self, from: jsonData)

            #expect(decoded == code)
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeStringDecoding(code: ResponseCode) throws {
            let jsonString = "\"\(code.rawValue)\""
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(ResponseCode.self, from: jsonData)

            #expect(decoded == code)
        }

        @Test(arguments: ResponseCode.allCases)
        func responseCodeDoubleDecoding(code: ResponseCode) throws {
            let jsonString = "\(code.rawValue).00"
            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(ResponseCode.self, from: jsonData)

            #expect(decoded == code)
        }
    }
}
