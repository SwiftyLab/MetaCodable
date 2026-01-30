import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Sequence Coder Tests")
struct SequenceCoderTests {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    @Test("Decodes from JSON successfully (SequenceCoderTests #67)")
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #68)")
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test("Encodes and decodes successfully (SequenceCoderTests #30)")
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #69)")
    func invalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(Container.self, from: json)
        }
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #70)")
    func lossyInvalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try decoder.decode(LossyContainer.self, from: json)
        }
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #71)")
    func lossyEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data.isEmpty)
    }

    @Test("Encodes and decodes successfully (SequenceCoderTests #31)")
    func lossyValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #72)")
    func lossyInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #73)")
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #74)")
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("Encodes and decodes successfully (SequenceCoderTests #32)")
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #75)")
    func defaultInvalidData() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
            let _ = try decoder.decode(DefaultContainer.self, from: json)
        }
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #76)")
    func lossyDefaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("Decodes from JSON successfully (SequenceCoderTests #77)")
    func lossyDefaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test("Encodes and decodes successfully (SequenceCoderTests #33)")
    func lossyDefaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try decoder.decode(LossyDefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try encoder.encode(val)
        #expect(data == json)
    }

    @Test("Encodes and decodes successfully (SequenceCoderTests #34)")
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
