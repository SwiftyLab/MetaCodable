import MetaCodable

@Codable
@CodingKeys(.snake_case)
struct Post {
    let id: String
    @CodedAt("header")
    let title: String
    let likes: Int
    let createdAt: String
}
