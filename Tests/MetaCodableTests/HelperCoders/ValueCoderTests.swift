import HelperCoders
import MetaCodable
import XCTest

final class ValueCoderTests: XCTestCase {
    func testActualTypeDecoding() throws {
        let json = try json(true, 5, 5.5, "some")
        let model = try JSONDecoder().decode(Model.self, from: json)
        XCTAssertTrue(model.bool)
        XCTAssertEqual(model.int, 5)
        XCTAssertEqual(model.double, 5.5)
        XCTAssertEqual(model.string, "some")
        let encoded = try JSONEncoder().encode(model)
        let parsedModel = try JSONDecoder().decode(Model.self, from: encoded)
        XCTAssertTrue(parsedModel.bool)
        XCTAssertEqual(parsedModel.int, 5)
        XCTAssertEqual(parsedModel.double, 5.5)
        XCTAssertEqual(parsedModel.string, "some")
    }

    // MARK: Bool
    func testIntToBooleanDecoding() throws {
        let json1 = try json(1, 5, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertTrue(model1.bool)
        let json2 = try json(0, 5, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertFalse(model2.bool)
    }

    func testIntToBooleanDecodingFailure() throws {
        do {
            let json = try json(2, 5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
            XCTFail("Invalid int to bool conversion")
        } catch {}
    }

    func testFloatToBooleanDecoding() throws {
        let json1 = try json(1.0, 5, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertTrue(model1.bool)
        let json2 = try json(0.0, 5, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertFalse(model2.bool)
    }

    func testFloatToBooleanDecodingFailure() throws {
        do {
            let json = try json(1.1, 5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
            XCTFail("Invalid float to bool conversion")
        } catch {}
    }

    func testStringToBooleanDecoding() throws {
        for str in ["1", "y", "t", "yes", "true", "1.0"] {
            let json = try json(str, 5, 5.5, "some")
            let model = try JSONDecoder().decode(Model.self, from: json)
            XCTAssertTrue(model.bool)
        }
        for str in ["0", "n", "f", "no", "false", "0.0"] {
            let json = try json(str, 5, 5.5, "some")
            let model = try JSONDecoder().decode(Model.self, from: json)
            XCTAssertFalse(model.bool)
        }
    }

    func testStringToBooleanDecodingFailure() throws {
        for str in ["0.1", "1.1", "2", "random"] {
            let json = try json(str, 5, 5.5, "some")
            do {
                let _ = try JSONDecoder().decode(Model.self, from: json)
                XCTFail("Invalid string \"\(str)\" to bool conversion")
            } catch {}
        }
    }

    // MARK: Int
    func testBoolToIntDecoding() throws {
        let json1 = try json(true, true, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.int, 1)
        let json2 = try json(true, false, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.int, 0)
    }

    func testFloatToIntDecoding() throws {
        let json1 = try json(true, 5.0, 5.5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.int, 5)
        let json2 = try json(true, 0.00, 5.5, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.int, 0)
    }

    func testFloatToIntDecodingFailure() throws {
        do {
            let json = try json(true, 5.5, 5.5, "some")
            let _ = try JSONDecoder().decode(Model.self, from: json)
            XCTFail("Invalid float to int conversion")
        } catch {}
    }

    func testStringToIntDecoding() throws {
        for str in ["1", "1.0", "0.00"] {
            let json = try json(true, str, 5.5, "some")
            let model = try JSONDecoder().decode(Model.self, from: json)
            XCTAssertEqual(model.int, Int(str) ?? Int(Double(str) ?? 0))
        }
    }

    func testStringToIntDecodingFailure() throws {
        for str in ["0.1", "1.1"] {
            let json = try json(true, str, 5.5, "some")
            do {
                let _ = try JSONDecoder().decode(Model.self, from: json)
                XCTFail("Invalid string \"\(str)\" to bool conversion")
            } catch {}
        }
    }

    // MARK: Float
    func testBoolToFloatDecoding() throws {
        let json1 = try json(true, 5, true, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.double, 1)
        let json2 = try json(true, 5, false, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.double, 0)
    }

    func testIntToFloatDecoding() throws {
        let json1 = try json(true, 5, 5, "some")
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.double, 5)
        let json2 = try json(true, 5, 0, "some")
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.double, 0)
    }

    func testStringToFloatDecoding() throws {
        for str in ["1", "1.0", "0.00", "1.01"] {
            let json = try json(true, 5, str, "some")
            let model = try JSONDecoder().decode(Model.self, from: json)
            XCTAssertEqual(model.double, Double(str))
        }
    }

    func testStringToFloatDecodingFailure() throws {
        for str in ["0.1.1", "random"] {
            let json = try json(true, 5, str, "some")
            do {
                let _ = try JSONDecoder().decode(Model.self, from: json)
                XCTFail("Invalid string \"\(str)\" to bool conversion")
            } catch {}
        }
    }

    // MARK: String
    func testBoolToStringDecoding() throws {
        let json1 = try json(true, 5, 5.5, true)
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.string, "true")
        let json2 = try json(true, 5, 5.5, false)
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.string, "false")
    }

    func testIntToStringDecoding() throws {
        let json1 = try json(true, 5, 5.5, 5)
        let model1 = try JSONDecoder().decode(Model.self, from: json1)
        XCTAssertEqual(model1.string, "5")
        let json2 = try json(true, 5, 5.5, 0)
        let model2 = try JSONDecoder().decode(Model.self, from: json2)
        XCTAssertEqual(model2.string, "0")
    }

    func testFloatToStringDecoding() throws {
        for number in [1.0, 0.00, 1.01] {
            let json = try json(true, 5, 5.5, number)
            let model = try JSONDecoder().decode(Model.self, from: json)
            XCTAssertEqual(Double(model.string), number)
        }
    }
}

fileprivate func json(
    _ bool: some Codable,
    _ int: some Codable,
    _ double: some Codable,
    _ string: some Codable,
    file: StaticString = #file,
    line: UInt = #line
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
    return try XCTUnwrap(
        jsonStr.data(using: .utf8),
        file: file, line: line
    )
}

@Codable
fileprivate struct Model {
    @CodedBy(ValueCoder<Bool>())
    let bool: Bool
    @CodedBy(ValueCoder<Int>())
    let int: Int
    @CodedBy(ValueCoder<Double>())
    let double: Double
    @CodedBy(ValueCoder<String>())
    let string: String
}
