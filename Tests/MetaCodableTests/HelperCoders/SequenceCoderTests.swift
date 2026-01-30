import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Sequence Coder Tests")
struct SequenceCoderTests {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    @Test("invalid Data Type")
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test("empty Data")
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test("valid Data")
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("invalid Data")
    func invalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test("lossy Invalid Data Type")
    func lossyInvalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(LossyContainer.self, from: json)
        }
    }

    @Test("lossy Empty Data")
    func lossyEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test("lossy Valid Data")
    func lossyValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("lossy Invalid Data")
    func lossyInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Test("default Invalid Data Type")
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("default Empty Data")
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("default Valid Data")
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("default Invalid Data")
    func defaultInvalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(DefaultContainer.self, from: json)
        }
    }

    @Test("lossy Default Invalid Data Type")
    func lossyDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("lossy Default Empty Data")
    func lossyDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("lossy Default Valid Data")
    func lossyDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("lossy Default Invalid Data")
    func lossyDefaultInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let _ = try encoder.encode(val)
    }

    @Codable
    struct Container {
        @CodedBy(SequenceCoder(output: [String].self))
        let data: [String]
    }

    @Codable
    struct LossyContainer {
        @CodedBy(SequenceCoder(output: [String].self, configuration: .lossy))
        let data: [String]
    }

    @Codable
    @MemberInit
    struct DefaultContainer {
        @CodedBy(SequenceCoder(configuration: .default(["some"])))
        let data: [String]
    }

    @Codable
    @MemberInit
    struct LossyDefaultContainer {
        @CodedBy(SequenceCoder(configuration: [.lossy, .default(["some"])]))
        let data: [String]
    }
}
