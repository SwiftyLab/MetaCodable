import Foundation
import MetaCodable
import Testing

@Suite("Lossy Sequence Tests")
struct LossySequenceTests {
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("invalid Data Type")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("empty Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == [])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("valid Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("invalid Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("optional Invalid Data Type")
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
    @Test("optional Empty Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalEmptyData() throws {
        let json = "{}".data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == nil)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("optional Valid Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("optional Invalid Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("default Invalid Data Type")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("default Empty Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == [])
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("default Valid Data")
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    @Test("default Invalid Data")
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
