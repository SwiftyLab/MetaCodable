struct MetadataCoder: ExternalHelperCoder {
    struct AnyCodingKey: CodingKey {
        let stringValue: String

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    func decode(from decoder: Decoder) throws -> [String: Any] {
        let result: [String: Any] = [:]
        return result
    }

    func encode(_ value: [String : Any], to encoder: Encoder) throws {
        //
    }
}
