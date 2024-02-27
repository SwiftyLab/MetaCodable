import MetaCodable

@Codable
struct User {
    @CodedBy(
        TwoKeyCoder<String>(
            decodingKey: "email",
            encodingKey: "emailAddress"
        )
    )
    let email: String
}

struct TwoKeyCoder<Coded>: HelperCoder
where Coded: Codable {
    let decodingKey: String
    let encodingKey: String

    func decode(from decoder: Decoder) throws -> Coded {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = CodingKeys(stringValue: decodingKey)
        return try container.decode(Coded.self, forKey: key)
    }

    func encode(_ value: Coded, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let key = CodingKeys(stringValue: encodingKey)
        try container.encode(value, forKey: key)
    }

    struct CodingKeys: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
