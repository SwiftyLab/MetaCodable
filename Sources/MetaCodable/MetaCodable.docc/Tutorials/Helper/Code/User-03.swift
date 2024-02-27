import MetaCodable

@Codable
struct User {
    let email: String
}

struct TwoKeyCoder<Coded>: HelperCoder
where Coded: Codable {
    let decodingKey: String
    let encodingKey: String

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
