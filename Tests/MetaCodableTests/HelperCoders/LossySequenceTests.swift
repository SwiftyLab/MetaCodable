import MetaCodable
import XCTest

final class LossySequenceTests: XCTestCase {

    func testInvalidDataType() throws {
        do {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(Container.self, from: json)
            XCTFail("Invalid data type instead of array")
        } catch {}
    }

    func testEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try JSONEncoder().encode(val)
        XCTAssertEqual(data, json)
    }

    func testInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }

    func testOptionalInvalidDataType() throws {
        do {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(
                OptionalContainer.self, from: json
            )
            XCTFail("Invalid data type instead of array")
        } catch {}
    }

    func testOptionalEmptyData() throws {
        let json = "{}".data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        XCTAssertNil(val.data)
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
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }

    func testDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["some"])
    }

    func testDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try JSONEncoder().encode(val)
        XCTAssertEqual(data, json)
    }

    func testDefaultInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }
}

@Codable
fileprivate struct Container {
    @CodedBy(LossySequenceCoder<[String]>())
    let data: [String]
}

@Codable
@MemberInit
fileprivate struct DefaultContainer {
    @Default(["some"])
    @CodedBy(LossySequenceCoder<[String]>())
    let data: [String]
}

@Codable
fileprivate struct OptionalContainer {
    @CodedBy(LossySequenceCoder<[String]>())
    let data: [String]?
}
