import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Helper Coders Tests")
struct HelperCodersTests {
    @Test("Encodes and decodes with JSON successfully (HelperCodersTests #11)")
    func conditionalAndOptionalCoding() throws {
        let jsonStr = """
            {
                "date": "1997-11-04T10:38:21Z"
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(Model.self, from: json)
        let epoch: Double = 878_639_901
        #expect(model.date.timeIntervalSince1970 == epoch)
        #expect(model.optionalDate == nil)
        let encoded = try JSONEncoder().encode(model)
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = .secondsSince1970
        let newModel = try customDecoder.decode(MirrorModel.self, from: encoded)
        #expect(newModel.date.timeIntervalSince1970 == epoch)
        #expect(model.optionalDate == nil)
    }

    @Test("Encodes and decodes with JSON successfully (HelperCodersTests #12)")
    func propertyWrapperCoding() throws {
        let jsonStr = """
            {
                "int": 100
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(PropModel.self, from: json)
        #expect(model.int == 5)
        let encoded = try JSONEncoder().encode(model)
        let obj = try JSONSerialization.jsonObject(with: encoded)
        let dict = try #require(obj as? [String: Any])
        #expect(dict["int"] as? Int == 5)
    }

    @Codable
    struct Model {
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

    struct MirrorModel: Codable {
        let date: Date
        let optionalDate: Date?
    }

    @Codable
    struct PropModel {
        @CodedBy(PropertyWrapperCoder<HelperCodersTests.ConstIntCoder>())
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
}
