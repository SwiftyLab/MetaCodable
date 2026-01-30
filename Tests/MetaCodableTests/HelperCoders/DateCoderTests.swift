import Foundation
import HelperCoders
import MetaCodable
import Testing

@Suite("Date Coder Tests")
struct DateCoderTests {
    @Test("Encodes and decodes with JSON successfully (DateCoderTests #10)")
    func decoding() throws {
        let jsonStr = """
            {
                "epochSeconds": 878639901,
                "epochMilliSeconds": 878639901000,
                "epochMicroSeconds": 878639901000000,
                "epochNanoSeconds": 878639901000000000,
                "iso8601Date": "1997-11-04T10:38:21Z",
                "formattedDate": "1997-11-04T10:38:21+00:00"
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        let model = try JSONDecoder().decode(Model.self, from: json)
        let epoch: Double = 878_639_901
        #expect(model.epochSeconds.timeIntervalSince1970 == epoch)
        #expect(model.epochMilliSeconds.timeIntervalSince1970 == epoch)
        #expect(model.epochMicroSeconds.timeIntervalSince1970 == epoch)
        #expect(model.epochNanoSeconds.timeIntervalSince1970 == epoch)
        #expect(model.iso8601Date.timeIntervalSince1970 == epoch)
        #expect(model.formattedDate.timeIntervalSince1970 == epoch)
        let encoded = try JSONEncoder().encode(model)
        let newModel = try JSONDecoder().decode(Model.self, from: encoded)
        #expect(newModel == model)
    }

    @Test("Decodes from JSON successfully (DateCoderTests #56)")
    func invalidDecoding() throws {
        let jsonStr = """
            {
                "epochSeconds": 878639901,
                "epochMilliSeconds": 878639901000,
                "epochMicroSeconds": 878639901000000,
                "epochNanoSeconds": 878639901000000000,
                "iso8601Date": "invalid date",
                "formattedDate": "1997-11-04T10:38:21+00:00"
            }
            """
        let json = try #require(jsonStr.data(using: .utf8))
        #expect(throws: DecodingError.self) {
            let _ = try JSONDecoder().decode(Model.self, from: json)
        }
    }

    @Codable
    struct Model: Equatable {
        @CodedBy(Since1970DateCoder())
        let epochSeconds: Date
        @CodedBy(Since1970DateCoder(intervalType: .milliseconds))
        let epochMilliSeconds: Date
        @CodedBy(Since1970DateCoder(intervalType: .microseconds))
        let epochMicroSeconds: Date
        @CodedBy(Since1970DateCoder(intervalType: .nanoseconds))
        let epochNanoSeconds: Date

        @CodedBy(ISO8601DateCoder())
        let iso8601Date: Date
        @CodedBy(DateCoder(formatter: RFC3339DateFormatter))
        let formattedDate: Date
    }
}

private let RFC3339DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
