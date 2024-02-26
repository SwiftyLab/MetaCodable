import MetaCodable

@Codable
struct User {
    let email: String
}

struct TwoKeyCoder<Coded>: HelperCoder
where Coded: Codable {
    let decodingKey: String
    let encodingKey: String
}
