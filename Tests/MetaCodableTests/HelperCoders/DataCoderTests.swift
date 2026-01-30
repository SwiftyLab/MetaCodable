import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Data Coder Tests")
struct DataCoderTests {
    @Test("Encodes and decodes with JSON successfully (DataCoderTests #9)")
    func decoding() throws {
        let jsonStr = """
            {
                "data": "SGVsbG8h"
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(Model.self, from: json)
        #expect(String(data: model.data, encoding: .utf8) == "Hello!")
        let encoded = try JSONEncoder().encode(model)
        let newModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(newModel == model)
    }

    @Test("Decodes from JSON successfully (DataCoderTests #55)")
    func invalidDataDecoding() throws {
        let jsonStr = """
            {
                "data": "invalid data"
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        #expect(throws: DecodingError.self) {
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    @Codable
    struct Model: Equatable {
        @CodedBy(Base64Coder())
        let data: Data
    }
}
