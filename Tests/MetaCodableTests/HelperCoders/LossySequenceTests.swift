import Foundation
import MetaCodable
import Testing

@Suite("Lossy Sequence Tests")
struct LossySequenceTests {
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #57)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #58)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == [])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Encodes and decodes successfully (LossySequenceTests #22)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #59)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #60)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalInvalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(
                OptionalContainer.self, from: json
            )
        }
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #61)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalEmptyData() throws {
        let json = "{}".data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == nil)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Encodes and decodes successfully (LossySequenceTests #23)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #62)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #63)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #64)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == [])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Encodes and decodes successfully (LossySequenceTests #24)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("Decodes from JSON successfully (LossySequenceTests #65)")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Codable
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    struct Container {
        @CodedBy(LossySequenceCoder<[String]>())
        let data: [String]
    }

    @Codable
    @MemberInit
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    struct DefaultContainer {
        @Default(["some"])
        @CodedBy(LossySequenceCoder<[String]>())
        let data: [String]
    }

    @Codable
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    struct OptionalContainer {
        @CodedBy(LossySequenceCoder<[String]>())
        let data: [String]?
    }
}
