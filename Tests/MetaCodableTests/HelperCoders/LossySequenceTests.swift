import Foundation
import MetaCodable
import Testing

struct LossySequenceTests {
    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func emptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == [])
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func validData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func invalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(Container.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalInvalidDataType() throws {
        #expect(throws: DecodingError.self) {
            let json = #"{"data":1}"#.data(using: .utf8)!
            let _ = try JSONDecoder().decode(
                OptionalContainer.self, from: json
            )
        }
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalEmptyData() throws {
        let json = "{}".data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == nil)
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func optionalInvalidData() throws {
        let json = #"{"data":[1,"1",2,"2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(val.data == ["1", "2"])
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultInvalidDataType() throws {
        let json = #"{"data":1}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["some"])
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultEmptyData() throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == [])
    }

    @Test
    @available(*, deprecated, message: "Tesing deprecated LossySequenceCoder")
    func defaultValidData() throws {
        let json = #"{"data":["1","2"]}"#.data(using: .utf8)!
        let val = try JSONDecoder().decode(DefaultContainer.self, from: json)
        #expect(val.data == ["1", "2"])
        let data = try JSONEncoder().encode(val)
        #expect(data == json)
    }

    @Test
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
