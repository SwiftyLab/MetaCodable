import Foundation
import HelperCoders
import MetaCodable
import Testing

struct SequenceCoderTests {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    @Test
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test
    func invalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test
    func lossyInvalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(LossyContainer.self, from: json)
        }
    }

    @Test
    func lossyEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test
    func lossyValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test
    func lossyInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Test
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test
    func defaultInvalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(DefaultContainer.self, from: json)
        }
    }

    @Test
    func lossyDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test
    func lossyDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test
    func lossyDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test
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
