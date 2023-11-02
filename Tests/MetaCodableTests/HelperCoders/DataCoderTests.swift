import HelperCoders
import MetaCodable
import XCTest

final class DataCoderTests: XCTestCase {
    func testDecoding() throws {
        let jsonStr = """
            {
                "data": "SGVsbG8h"
            }
            """
        let json = try XCTUnwrap(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertEqual(String(data: model.data, encoding: .utf8), "Hello!")
        let encoded = try JSONEncoder().encode(model)
        let newModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertEqual(newModel, model)
    }

    func testInvalidDataDecoding() throws {
        let jsonStr = """
            {
                "data": "invalid data"
            }
            """
        let json = try XCTUnwrap(jsonStr.data(using: .utf8))
        do {
            let _ = try JSONDecoder().decode(Model.self, from: json)
            XCTFail("Invalid Base64 conversion")
        } catch {}
    }
}

@Codable
fileprivate struct Model: Equatable {
    @CodedBy(Base64Coder())
    let data: Data
}
