import HelperCoders
import MetaCodable
import XCTest

final class SequenceCoderTests: XCTestCase {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    func testInvalidDataType() throws {
        do {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
            XCTFail("Invalid data type instead of array")
        } catch {}
    }

    func testEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try encoder.encode(val)
        XCTAssertEqual(data, json)
    }

    func testInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        do {
            let _ = try decoder.decode(Container.self, from: json)
            XCTFail("Invalid sequence decoding")
        } catch {}
    }

    func testLossyInvalidDataType() throws {
        do {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(LossyContainer.self, from: json)
            XCTFail("Invalid data type instead of array")
        } catch {}
    }

    func testLossyEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        XCTAssertEqual(val.data, [])
    }

    func testLossyValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try encoder.encode(val)
        XCTAssertEqual(data, json)
    }

    func testLossyInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
    }

    func testDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["some"])
    }

    func testDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["some"])
    }

    func testDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try encoder.encode(val)
        XCTAssertEqual(data, json)
    }

    func testDefaultInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        do {
            let _ = try decoder.decode(DefaultContainer.self, from: json)
            XCTFail("Invalid sequence decoding")
        } catch {}
    }

    func testLossyDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["some"])
    }

    func testLossyDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["some"])
    }

    func testLossyDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let data = try encoder.encode(val)
        XCTAssertEqual(data, json)
    }

    func testLossyDefaultInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        XCTAssertEqual(val.data, ["1", "2"])
        let _ = try encoder.encode(val)
    }
}

@Codable
fileprivate struct Container {
    @CodedBy(SequenceCoder(output: [String].self))
    let data: [String]
}

@Codable
fileprivate struct LossyContainer {
    @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
    let data: [String]
}

@Codable
@MemberInit
fileprivate struct DefaultContainer {
    @CodedBy(SequenceCoder(configuration: .default(["some"])))
    let data: [String]
}

@Codable
@MemberInit
fileprivate struct LossyDefaultContainer {
    @CodedBy(SequenceCoder(configuration: [.lossy, .default(["some"])]))
    let data: [String]
}
