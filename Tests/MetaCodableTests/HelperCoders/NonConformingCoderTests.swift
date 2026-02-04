import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Non Conforming Coder Tests")
struct NonConformingCoderTests {
    @Test("Encodes and decodes successfully (NonConformingCoderTests #25)", .tags(.decoding, .encoding, .nonConformingCoder))
    func testDecodingActualFloat() throws {
        let json = try mockJSON(5.5)
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.float == 5.5)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.float == 5.5)
    }

    @Test("Encodes and decodes successfully (NonConformingCoderTests #26)", .tags(.decoding, .encoding, .nonConformingCoder))
    func testDecodingStringifiedFloat() throws {
        let json = try mockJSON("5.5")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.float == 5.5)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.float == 5.5)
    }

    @Test("Encodes and decodes successfully (NonConformingCoderTests #27)", .tags(.decoding, .encoding, .nonConformingCoder))
    func testDecodingPositiveInfinity() throws {
        let json = try mockJSON("➕♾️")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.float == .infinity)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.float == .infinity)
    }

    @Test("Encodes and decodes successfully (NonConformingCoderTests #28)", .tags(.decoding, .encoding, .nonConformingCoder))
    func testDecodingNegativeInfinity() throws {
        let json = try mockJSON("➖♾️")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.float == -.infinity)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.float == -.infinity)
    }

    @Test("Encodes and decodes successfully (NonConformingCoderTests #29)", .tags(.decoding, .encoding, .nonConformingCoder))
    func testDecodingNotANumber() throws {
        let json = try mockJSON("😞")
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(model.float.isNaN)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(parsedModel.float.isNaN)
    }

    @Test("Decodes from JSON successfully (NonConformingCoderTests #66)", .tags(.decoding, .nonConformingCoder))
    func invalidDecoding() throws {
        let json = try mockJSON("random")
        #expect(throws: DecodingError.self) {
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    func mockJSON(
        _ float: some Codable,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws -> Data {
        let quote = float is String ? "\"" : ""
        let jsonStr = """
            {
                "float": \(quote)\(float)\(quote)
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
        @CodedBy(
            NonConformingCoder<Double>(
                positiveInfinity: "➕♾️",
                negativeInfinity: "➖♾️",
                nan: "😞"
            )
        )
        let float: Double
    }
}
