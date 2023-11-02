import HelperCoders
import MetaCodable
import XCTest

final class NonConformingCoderTests: XCTestCase {
    func testDecodingActualFloat() throws {
        let json = try json(5.5)
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertEqual(model.float, 5.5)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertEqual(parsedModel.float, 5.5)
    }

    func testDecodingStringifiedFloat() throws {
        let json = try json("5.5")
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertEqual(model.float, 5.5)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertEqual(parsedModel.float, 5.5)
    }

    func testDecodingPositiveInfinity() throws {
        let json = try json("➕♾️")
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertEqual(model.float, .infinity)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertEqual(parsedModel.float, .infinity)
    }

    func testDecodingNegativeInfinity() throws {
        let json = try json("➖♾️")
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertEqual(model.float, -.infinity)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertEqual(parsedModel.float, -.infinity)
    }

    func testDecodingNotANumber() throws {
        let json = try json("😞")
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertTrue(model.float.isNaN)
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertTrue(parsedModel.float.isNaN)
    }

    func testInvalidDecoding() throws {
        let json = try json("random")
        do {
            let _ = try JSONDecoder().decode(Model.self, from: json)
            XCTFail("Invalid string to float conversion")
        } catch {}
    }
}

fileprivate func json(
    _ float: some Codable,
    file: StaticString = #file,
    line: UInt = #line
) throws -> Data {
    let quote = float is String ? "\"" : ""
    let jsonStr = """
        {
            "float": \(quote)\(float)\(quote)
        }
        """
    return try XCTUnwrap(
        jsonStr.data(using: .utf8),
        file: file, line: line
    )
}

@Codable
fileprivate struct Model {
    @CodedBy(
        NonConformingCoder<Double>(
            positiveInfinity: "➕♾️",
            negativeInfinity: "➖♾️",
            nan: "😞"
        )
    )
    let float: Double
}
