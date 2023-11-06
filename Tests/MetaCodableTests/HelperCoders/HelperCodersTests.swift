import HelperCoders
import MetaCodable
import XCTest

final class HelperCodersTests: XCTestCase {
    func testConditionalAndOptionalCoding() throws {
        let jsonStr = """
            {
                "date": "1997-11-04T10:38:21Z"
            }
            """
        let json = try XCTUnwrap(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(Model.self, from: json)
        let epoch: Double = 878639901
        XCTAssertEqual(model.date.timeIntervalSince1970, epoch)
        XCTAssertNil(model.optionalDate)
        let encoded = try JSONEncoder().encode(model)
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = .secondsSince1970
        let newModel = try customDecoder.decode(MirrorModel.self, from: encoded)
        XCTAssertEqual(newModel.date.timeIntervalSince1970, epoch)
        XCTAssertNil(model.optionalDate)
    }

    func testPropertyWrapperCoding() throws {
        let jsonStr = """
            {
                "int": 100
            }
            """
        let json = try XCTUnwrap(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(PropModel.self, from: json)
        XCTAssertEqual(model.int, 5)
        let encoded = try JSONEncoder().encode(model)
        let obj = try JSONSerialization.jsonObject(with: encoded)
        let dict = try XCTUnwrap(obj as? [String: Any])
        XCTAssertEqual(dict["int"] as? Int, 5)
    }
}

@Codable
fileprivate struct Model {
    @CodedBy(
        ConditionalCoder(
            decoder: ISO8601DateCoder(),
            encoder: Since1970DateCoder()
        )
    )
    let date: Date
    @CodedBy(
        ConditionalCoder(
            decoder: ISO8601DateCoder(),
            encoder: Since1970DateCoder()
        )
    )
    let optionalDate: Date?
}

fileprivate struct MirrorModel: Codable {
    let date: Date
    let optionalDate: Date?
}

@Codable
fileprivate struct PropModel {
    @CodedBy(PropertyWrapperCoder<ConstIntCoder>())
    let int: Int
}

@propertyWrapper
struct ConstIntCoder: PropertyWrappable {
    var wrappedValue: Int { 5 }

    init(wrappedValue: Int) {}

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}
