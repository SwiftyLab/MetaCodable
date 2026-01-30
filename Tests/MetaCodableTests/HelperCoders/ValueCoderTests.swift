import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Value Coder Tests")
struct ValueCoderTests {
    @Test("Encodes and decodes successfully (ValueCoderTests #35)", .tags(.decoding, .encoding, .valueCoder))
    func actualTypeDecoding() throws {
        let json = try mockJSON(true, 5, 5.5, "some")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.bool)
        #expect(model.int == 5)
        #expect(model.double == 5.5)
        #expect(model.string == "some")
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.bool)
        #expect(parsedModel.int == 5)
        #expect(parsedModel.double == 5.5)
        #expect(parsedModel.string == "some")
    }

    // MARK: Bool
    @Test("Decodes from JSON successfully (ValueCoderTests #78)", .tags(.decoding, .valueCoder))
    func intToBooleanDecoding() throws {
        let json1 = try mockJSON(1, 5, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.bool)
        let json2 = try mockJSON(0, 5, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(!model2.bool)
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #79)", .tags(.decoding, .valueCoder))
    func intToBooleanDecodingFailure() throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(2, 5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #80)", .tags(.decoding, .valueCoder))
    func floatToBooleanDecoding() throws {
        let json1 = try mockJSON(1.0, 5, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.bool)
        let json2 = try mockJSON(0.0, 5, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(!model2.bool)
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #81)", .tags(.decoding, .valueCoder))
    func floatToBooleanDecodingFailure() throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(1.1, 5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    @Test(
        arguments: zip(
            ["1", "y", "t", "yes", "true", "1.0"] + [
                "0", "n", "f", "no", "false", "0.0",
            ],
            Array(repeating: true, count: 6) + Array(repeating: false, count: 6)
        )
    )
    func stringToBooleanDecoding(_ str: String, _ result: Bool) throws {
        let json = try mockJSON(str, 5, 5.5, "some")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.bool == result)
    }

    @Test(arguments: ["0.1", "1.1", "2", "random"])
    func stringToBooleanDecodingFailure(_ str: String) throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(str, 5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    // MARK: Int
    @Test("Decodes from JSON successfully (ValueCoderTests #82)", .tags(.decoding, .valueCoder))
    func boolToIntDecoding() throws {
        let json1 = try mockJSON(true, true, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.int == 1)
        let json2 = try mockJSON(true, false, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.int == 0)
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #83)", .tags(.decoding, .valueCoder))
    func floatToIntDecoding() throws {
        let json1 = try mockJSON(true, 5.0, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.int == 5)
        let json2 = try mockJSON(true, 0.00, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.int == 0)
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #84)", .tags(.decoding, .valueCoder))
    func floatToIntDecodingFailure() throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(true, 5.5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    @Test(arguments: ["1", "1.0", "0.00"])
    func stringToIntDecoding(_ str: String) throws {
        let json = try mockJSON(true, str, 5.5, "some")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.int == Int(str) ?? Int(Double(str) ?? 0))
    }

    @Test(arguments: ["0.1", "1.1"])
    func stringToIntDecodingFailure(_ str: String) throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(true, str, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    // MARK: Float
    @Test("Decodes from JSON successfully (ValueCoderTests #85)", .tags(.decoding, .valueCoder))
    func boolToFloatDecoding() throws {
        let json1 = try mockJSON(true, 5, true, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.double == 1)
        let json2 = try mockJSON(true, 5, false, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.double == 0)
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #86)", .tags(.decoding, .valueCoder))
    func intToFloatDecoding() throws {
        let json1 = try mockJSON(true, 5, 5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.double == 5)
        let json2 = try mockJSON(true, 5, 0, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.double == 0)
    }

    @Test(arguments: ["1", "1.0", "0.00", "1.01"])
    func stringToFloatDecoding(_ str: String) throws {
        let json = try mockJSON(true, 5, str, "some")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.double == Double(str))
    }

    @Test(arguments: ["0.1.1", "random"])
    func stringToFloatDecodingFailure(_ str: String) throws {
        #expect(throws: DecodingError.self) {
            let json = try mockJSON(true, 5, str, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    // MARK: String
    @Test("Decodes from JSON successfully (ValueCoderTests #87)", .tags(.decoding, .valueCoder))
    func boolToStringDecoding() throws {
        let json1 = try mockJSON(true, 5, 5.5, true)
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.string == "true")
        let json2 = try mockJSON(true, 5, 5.5, false)
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.string == "false")
    }

    @Test("Decodes from JSON successfully (ValueCoderTests #88)", .tags(.decoding, .valueCoder))
    func intToStringDecoding() throws {
        let json1 = try mockJSON(true, 5, 5.5, 5)
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        #expect(model1.string == "5")
        let json2 = try mockJSON(true, 5, 5.5, 0)
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        #expect(model2.string == "0")
    }

    @Test(arguments: [1.0, 0.00, 1.01])
    func floatToStringDecoding(_ number: Double) throws {
        let json = try mockJSON(true, 5, 5.5, number)
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(Double(model.string) == number)
    }

    func mockJSON(
        _ bool: some Codable,
        _ int: some Codable,
        _ double: some Codable,
        _ string: some Codable,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws -> Data {
        let boolQuote = bool is String ? "\"" : ""
        let intQuote = int is String ? "\"" : ""
        let doubleQuote = double is String ? "\"" : ""
        let stringQuote = string is String ? "\"" : ""
        let jsonStr = """
            {
                "bool": \(boolQuote)\(bool)\(boolQuote),
                "int": \(intQuote)\(int)\(intQuote),
                "double": \(doubleQuote)\(double)\(doubleQuote),
                "string": \(stringQuote)\(string)\(stringQuote)
            }
            """
        #if swift(>=6)
        return try #require(
            jsonStr.data(using: .utf8),
            sourceLocation: .init(
                fileID: String(fileID), filePath: String(filePath),
                line: Int(line), column: Int(column)
            )
        )
        #else
        return try #require(
            jsonStr.data(using: .utf8),
            sourceLocation: .init(
                fileID: fileID, filePath: filePath, line: line, column: column
            )
        )
        #endif
    }

    @Codable
    struct Model {
        @CodedBy(ValueCoder<Bool>())
        let bool: Bool
        @CodedBy(ValueCoder<Int>())
        let int: Int
        @CodedBy(ValueCoder<Double>())
        let double: Double
        @CodedBy(ValueCoder<String>())
        let string: String
    }
}
