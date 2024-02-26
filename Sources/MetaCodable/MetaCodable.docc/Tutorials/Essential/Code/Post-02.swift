import MetaCodable

@Codable
struct Post {
    let id: String
    let header: String
    let likes: Int
}
