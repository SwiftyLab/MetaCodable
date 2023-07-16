import XCTest
@testable import MetaCodable

final class LossySequenceTests: XCTestCase {

    func testInvalidDataType() throws {
        XCTExpectFailure("Invalid data type instead of array")
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testOptionalData() throws {
        let json = "{}".data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        XCTAssertNil(val.data)
    }

    func testValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try JSONEncoder().encode(val)
        XCTAssertEqual(data, json)
    }

    func testOptionalValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try JSONEncoder().encode(val)
        XCTAssertEqual(data, json)
    }

    func testOptionalInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }

    func testInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }
}

@Codable
struct Container {
    @CodedIn(helper: LossySequenceCoder<[String]>())
    let data: [String]
}

@Codable
struct OptionalContainer {
    @CodedIn(helper: LossySequenceCoder<[String]>())
    let data: [String]?
}
